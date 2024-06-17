import java.sql.*;
import java.time.*;
import java.time.format.*;
import java.text.DecimalFormat;
public class Main {
  public final static DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm:ss").withZone(ZoneId.systemDefault());
  public static void main(String[] args){
    System.exit(exec());
  }
  public static int exec(){
    final long startTime = System.currentTimeMillis();
    try{
      System.out.println("Application initialized at "+DATE_FORMATTER.format(Instant.ofEpochMilli(startTime)));
      if (Env.bad){
        System.out.println("Required environment variable(s) not defined.");
        return 1;
      }
      for (int i=0;i<Env.attempts;++i){
        Timestamp lastSync = null, s;
        String status = null;
        try{
          try(
            Connection qqube = DriverManager.getConnection("jdbc:sqlanywhere:DSN=QQubeFinancials");
            Statement qqubeStatement = qqube.createStatement();
          ){
            try(
              ResultSet sync = qqubeStatement.executeQuery("SELECT \"QQube Last Synch\", \"QQube Last Synch Status\" FROM QQubeUser.vd_Company;");
            ){
              while (sync.next()){
                s = sync.getTimestamp(1);
                if (lastSync==null || s.after(lastSync)){
                  lastSync = s;
                  status = sync.getString(2);
                }
              }
            }
          }
          if (lastSync==null || status==null){
            return 1;
          }
          long milli = startTime-lastSync.getTime();
          final boolean good = milli>34200000;//9.5 hours
          long hours = milli/3600000;
          milli-=hours*3600000;
          long minutes = milli/60000;
          milli-=minutes*60000;
          long seconds = milli/1000;
          System.out.println("Last sync occurred "+hours+" hours, "+minutes+" minutes, and "+seconds+" seconds ago.");
          if (good || !status.equalsIgnoreCase("Success")){
            System.out.println("Last Sync Status: "+status);
            return 1978;
          }
          return 0;
        }catch(Throwable t){
          if (i+1==Env.attempts){
            throw t;
          }
          Thread.sleep(300000L);
        }
      }
      return 1;
    }catch(Throwable t){
      t.printStackTrace();
      return 1;
    }finally{
      System.out.println("Execution lasted "+new DecimalFormat("#.##").format((System.currentTimeMillis()-startTime)/1000.0)+" seconds.");
    }
  }
}