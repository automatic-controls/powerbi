import java.time.*;
import java.time.format.*;
import java.text.DecimalFormat;
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
      try(
        final Connector c = new Connector(); 
      ){
        //TODO: set Env.attempts back to 3 and enable the email on exec error powershell thing
        c.sync();
      }
      System.out.println("Application terminated successfully.");
      return true;
    }catch(Throwable t){
      t.printStackTrace();
      return false;
    }finally{
      System.out.println("Execution lasted "+new DecimalFormat("#.##").format((System.currentTimeMillis()-startTime)/1000.0)+" seconds.");
    }
  }
}