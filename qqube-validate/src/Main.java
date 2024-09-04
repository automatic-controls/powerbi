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
      final ArrayList<Job> jobs = new ArrayList<>(4096);
      for (int i=0;i<Env.attempts;++i){
        try(
          Connection qqube = DriverManager.getConnection("jdbc:sqlanywhere:DSN=QQubeFinancials");
          Statement s = qqube.createStatement();
          ResultSet r = s.executeQuery(query);
        ){
          while (r.next()){
            jobs.add(new Job(r.getString(1), r.getString(2), r.getTimestamp(3), r.getString(4), r.getString(5), r.getString(6), r.getString(7), r.getString(8)));
          }
          break;
        }catch(Throwable t){
          jobs.clear();
          if (i+1==Env.attempts){
            throw t;
          }
          Thread.sleep(300000L);
        }
      }
      for (Job j:jobs){
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