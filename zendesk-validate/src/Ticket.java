import java.util.regex.*;
import java.util.*;
public class Ticket {
  private final static Pattern IGNORE = Pattern.compile("\\(.*?\\)");
  private final static Pattern JOB = Pattern.compile("(?:^|[\\s&,])([^\\s&,]++)(?=$|[\\s&,])");
  public volatile int id;
  public volatile String org;
  public volatile String subject;
  public volatile String name;
  public volatile String email;
  public volatile String jobID;
  public Ticket(int id, String org, String subject, String name, String email, String jobID){
    this.id = id;
    this.org = org;
    this.subject = subject;
    this.name = name;
    this.email = email;
    this.jobID = jobID;
  }
  public ArrayList<String> getJobs(){
    final ArrayList<String> jobs = new ArrayList<String>(8);
    IGNORE.splitAsStream(jobID).forEach(new java.util.function.Consumer<String>(){
      public void accept(String s){
        s = s.trim();
        if (!s.isEmpty()){
          final Matcher m = JOB.matcher(s);
          while (m.find()){
            s = m.group(1);
            if (Main.d(s,"ONSITE")>1 && Main.d(s,"OFFSITE")>1 && Main.d(s,"N/A")>1 && Main.d(s,"NONE")>1){
              jobs.add(s);
            }
          }
        }
      }
    });
    return jobs;
  }
}