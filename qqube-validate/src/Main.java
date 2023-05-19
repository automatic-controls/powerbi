import java.sql.*;
import java.time.*;
import java.time.format.*;
import java.text.DecimalFormat;
import java.util.*;
import java.nio.file.*;
public class Main {
  public final static DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm:ss").withZone(ZoneId.systemDefault());
  public static void main(String[] args){
    System.exit(exec()?Job.count:-1);
  }
  public static boolean exec(){
    final long startTime = System.currentTimeMillis();
    try{
      System.out.println("Application initialized at "+DATE_FORMATTER.format(Instant.ofEpochMilli(startTime)));
      if (Env.bad){
        System.out.println("Required environment variable(s) not defined.");
        return false;
      }
      final String query = new String(Files.readAllBytes(Paths.get(Main.class.getProtectionDomain().getCodeSource().getLocation().toURI()).getParent().resolve("query.sql")), java.nio.charset.StandardCharsets.UTF_8);
      TreeMap<String,Job> jobs = new TreeMap<String,Job>();
      for (int i=0;i<Env.attempts;++i){
        try(
          Connection qqube = DriverManager.getConnection("jdbc:sqlanywhere:DSN=QQubeFinancials");
          Statement s = qqube.createStatement();
          ResultSet r = s.executeQuery(query);
        ){
          Job j,k;
          while (r.next()){
            j = new Job(r.getString(1), r.getTimestamp(2), r.getString(3), r.getString(4), r.getString(5), r.getString(6), r.getString(7));
            if (j.id!=null){
              k = jobs.get(j.id);
              if (k==null || j.creationTime.after(k.creationTime)){
                jobs.put(j.id,j);
              }
            }
          }
          break;
        }catch(Throwable t){
          jobs.clear();
          if (i+1==Env.attempts){
            throw t;
          }
          Thread.sleep(5000);
        }
      }
      for (Job j:jobs.values()){
        j.validate();
      }
      return true;
    }catch(Throwable t){
      t.printStackTrace();
      return false;
    }finally{
      System.out.println("Execution lasted "+new DecimalFormat("#.##").format((System.currentTimeMillis()-startTime)/1000.0)+" seconds.");
    }
  }
}