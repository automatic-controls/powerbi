import java.sql.*;
import java.util.*;
public class DataUploader implements AutoCloseable {
  private Connection con = null;
  private void ensureConnect() throws SQLException {
    if (con!=null && !con.isValid(3000)){
      con.close();
      con = null;
    }
    if (con==null || con.isClosed()){
      con = DriverManager.getConnection("jdbc:postgresql://"+Env.postgresql_url+":"+Env.postgresql_port+"/"+Env.postgresql_database, Env.postgresql_user, Env.postgresql_pass);
      con.setAutoCommit(false);
    }
  }
  public void deleteUnlistedEmployees(Set<String> employees, java.sql.Date start, java.sql.Date end) throws Throwable {
    for (int i=1;i<=Env.attempts;++i){
      try{
        ensureConnect();
        try{
          final HashSet<String> unlistedEmployees = new HashSet<String>();
          try(
            final PreparedStatement p = con.prepareStatement("SELECT DISTINCT \"employee_number\" FROM timestar.timesheets_processed WHERE \"date\">=? AND \"date\"<=?;");
          ){
            p.setDate(1, start);
            p.setDate(2, end);
            try(
              final ResultSet r = p.executeQuery();
            ){
              String s;
              while (r.next()){
                if ((s=r.getString(1))!=null && !employees.contains(s)){
                  unlistedEmployees.add(s);
                }
              }
            }
          }
          if (unlistedEmployees.size()>0){
            try(
              final PreparedStatement p = con.prepareStatement("DELETE FROM timestar.timesheets_processed WHERE \"date\">=? AND \"date\"<=? AND \"employee_number\"=?;");
            ){
              p.setDate(1, start);
              p.setDate(2, end);
              for (String s:unlistedEmployees){
                p.setString(3, s);
                p.addBatch();
              }
              p.executeBatch();
            }
          }
          con.commit();
        }finally{
          con.rollback();
        }
        return;
      }catch(Throwable t){
        if (i==Env.attempts){
          throw t;
        }
        Thread.sleep(30000L);
      }
    }
  }
  public void submit(List<TimecardEntry> entries, java.sql.Date start, java.sql.Date end, String employeeNumber, String employeeName) throws Throwable {
    if (entries.isEmpty()){
      return;
    }
    for (int i=1;i<=Env.attempts;++i){
      try{
        ensureConnect();
        try{
          try(
            PreparedStatement p = con.prepareStatement("DELETE FROM timestar.timesheets_processed WHERE \"date\">=? AND \"date\"<=? AND \"employee_number\"=?;");
          ){
            p.setDate(1, start);
            p.setDate(2, end);
            p.setString(3, employeeNumber);
            p.executeUpdate();
          }
          try(
            PreparedStatement p = con.prepareStatement("INSERT INTO timestar.timesheets_processed VALUES(?,?,?,?,?,?,?,?,?,?,CURRENT_DATE);");
          ){
            p.setString(1,employeeNumber);
            p.setString(2,employeeName);
            boolean ot;
            for (TimecardEntry ent:entries){
              ent.pay_type = Utility.flatten(ent.pay_type);
              ot = ent.pay_type.equalsIgnoreCase("Overtime") || ent.pay_type.equalsIgnoreCase("OT") || ent.pay_type.equalsIgnoreCase("O/T");
              p.setDate(3,ent.date);
              p.setFloat(4,ent.seconds/3600.0f);
              p.setString(5,ent.pay_type);
              p.setBoolean(6,!ot);
              p.setBoolean(7,ot);
              p.setString(8,Utility.flatten(ent.work_category));
              p.setString(9,Utility.flatten(ent.job));
              p.setString(10,ent.notes);
              p.addBatch();
            }
            p.executeBatch();
          }
          con.commit();
        }finally{
          con.rollback();
        }
        return;
      }catch(Throwable t){
        if (i==Env.attempts){
          throw t;
        }
        Thread.sleep(30000L);
      }
    }
  }
  @Override public void close() throws SQLException {
    if (con!=null){
      con.close();
    }
  }
}