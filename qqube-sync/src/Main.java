import java.sql.*;
import java.time.*;
import java.time.format.*;
import java.text.DecimalFormat;
import java.nio.file.*;
public class Main {
  public final static DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm:ss").withZone(ZoneId.systemDefault());
  public static void main(String[] args){
    System.exit(exec()?0:1);
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
      long updates = 0;
      Timestamp lastModified = null;
      for (int i=0;i<Env.attempts;++i){
        try(
          Connection postgresql = DriverManager.getConnection("jdbc:postgresql://"+Env.postgresql_url+":5432/analytics", Env.postgresql_user, Env.postgresql_pass);
        ){
          postgresql.setAutoCommit(false);
          try{
            if (lastModified==null){
              try(
                Statement s = postgresql.createStatement();
                ResultSet r = s.executeQuery("SELECT MAX(\"time_modified\") FROM quickbooks.jobs;");
              ){
                if (r.next()){
                  lastModified = r.getTimestamp(1);
                }else{
                  System.out.println("Failed to retrieve lastModified timestamp from PostgreSQL database.");
                  return false;
                }
              }
              postgresql.commit();
              if (lastModified==null){
                lastModified = new Timestamp(0);
              }
            }
            try(
              Connection qqube = DriverManager.getConnection("jdbc:sqlanywhere:DSN=QQubeFinancials");
              PreparedStatement qqubeStatement = qqube.prepareStatement(query);
            ){
              qqubeStatement.setTimestamp(1, lastModified);
              try(
                ResultSet updatedJobs = qqubeStatement.executeQuery();
                PreparedStatement deleteStatement = postgresql.prepareStatement("DELETE FROM quickbooks.jobs WHERE \"id\"=?;");
                PreparedStatement insertStatement = postgresql.prepareStatement("INSERT INTO quickbooks.jobs VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);");
              ){
                while (updatedJobs.next()){
                  deleteStatement.setString(1, updatedJobs.getString(2));
                  insertStatement.setString(1, updatedJobs.getString(1));
                  insertStatement.setString(2, updatedJobs.getString(2));
                  insertStatement.setBoolean(3, updatedJobs.getBoolean(3));
                  insertStatement.setString(4, updatedJobs.getString(4));
                  insertStatement.setString(5, updatedJobs.getString(5));
                  insertStatement.setString(6, updatedJobs.getString(6));
                  insertStatement.setString(7, updatedJobs.getString(7));
                  insertStatement.setString(8, updatedJobs.getString(8));
                  insertStatement.setString(9, updatedJobs.getString(9));
                  insertStatement.setBigDecimal(10, updatedJobs.getBigDecimal(10));
                  insertStatement.setBigDecimal(11, updatedJobs.getBigDecimal(11));
                  insertStatement.setBigDecimal(12, updatedJobs.getBigDecimal(12));
                  insertStatement.setBigDecimal(13, updatedJobs.getBigDecimal(13));
                  insertStatement.setBigDecimal(14, updatedJobs.getBigDecimal(14));
                  insertStatement.setTimestamp(15, updatedJobs.getTimestamp(15));
                  insertStatement.setTimestamp(16, updatedJobs.getTimestamp(16));
                  insertStatement.setDate(17, updatedJobs.getDate(17));
                  insertStatement.setDate(18, updatedJobs.getDate(18));
                  insertStatement.setDate(19, updatedJobs.getDate(19));
                  deleteStatement.executeUpdate();
                  insertStatement.executeUpdate();
                  postgresql.commit();
                  ++updates;
                }
              }
            }
          }finally{
            postgresql.rollback();
          }
          break;
        }catch(Throwable t){
          updates = 0;
          if (i+1==Env.attempts){
            throw t;
          }
          Thread.sleep(300000L);
        }
      }
      System.out.println("Updated "+updates+" row(s).");
      return true;
    }catch(Throwable t){
      t.printStackTrace();
      return false;
    }finally{
      System.out.println("Execution lasted "+new DecimalFormat("#.##").format((System.currentTimeMillis()-startTime)/1000.0)+" seconds.");
    }
  }
}