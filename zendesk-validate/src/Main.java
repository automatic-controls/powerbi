import java.sql.*;
import java.time.*;
import java.time.format.*;
import java.text.DecimalFormat;
import java.util.*;
import java.util.regex.*;
import java.nio.file.*;
public class Main {
  public final static DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm:ss").withZone(ZoneId.systemDefault());
  public volatile static Path installation;
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
      installation = Paths.get(Main.class.getProtectionDomain().getCodeSource().getLocation().toURI()).getParent();
      final String query = new String(Files.readAllBytes(installation.resolve("query.sql")), java.nio.charset.StandardCharsets.UTF_8);
      final TreeMap<String,Job> jobs = new TreeMap<String,Job>();
      final ArrayList<Ticket> tickets = new ArrayList<Ticket>(256);
      try(
        Connection postgresql = DriverManager.getConnection("jdbc:postgresql://"+Env.postgresql_url+":5432/analytics", Env.postgresql_user, Env.postgresql_pass);
        Statement s = postgresql.createStatement();
      ){
        try(
          ResultSet r = s.executeQuery("SELECT \"id\", \"active\", \"name\" FROM quickbooks.jobs;");
        ){
          String str;
          while (r.next()){
            if ((str=r.getString(1))!=null){
              str = str.toUpperCase().trim();
              if (!str.isEmpty()){
                jobs.put(str, new Job(str, r.getBoolean(2), r.getString(3)));
              }
            }
          }
        }
        try(
          ResultSet r = s.executeQuery(query);
        ){
          while (r.next()){
            tickets.add(new Ticket(r.getInt(1), r.getString(2), r.getString(3), r.getString(4), r.getString(5), r.getString(6)));
          }
        }
      }
      int i;
      final StringMatch[] matches = new StringMatch[8];
      for (i=0;i<matches.length;++i){
        matches[i] = new StringMatch(null,-1);
      }
      final Set<String> ids = jobs.keySet();
      final TreeMap<String,Assignee> assignees = new TreeMap<String,Assignee>();
      Job j;
      Assignee ass = null;
      BadTicket bt;
      for (Ticket t:tickets){
        if (t.jobID!=null){
          t.jobID = t.jobID.toUpperCase().trim();
          if (!t.jobID.isEmpty() && d(t.jobID,"N/A")>1 && d(t.jobID,"NONE")>1){
            for (String job:t.getJobs()){
              if (!ids.contains(job)){
                if (ass==null || !ass.email.equals(t.email)){
                  ass = assignees.get(t.email);
                  if (ass==null){
                    ass = new Assignee(t.name, t.email);
                    assignees.put(t.email,ass);
                  }
                }
                bt = new BadTicket(t,job);
                bt.suggestions = new Job[matches.length];
                findMatches(job,ids,matches);
                for (i=0;i<matches.length;++i){
                  if (matches[i].rating!=-1 && (j=jobs.get(matches[i].s))!=null){
                    bt.suggestions[i] = j;
                  }else{
                    bt.suggestions[i] = null;
                  }
                }
                ass.problems.add(bt);
              }
            }
          }
        }
      }
      if (assignees.size()>0){
        final StringBuilder sb = new StringBuilder(8192);
        final StringBuilder sg = new StringBuilder(256);
        sb.append("<!DOCTYPE html><html lang=\"en\"><head><style>");
        sb.append("\ntable{border-collapse:collapse;margin:0;width:100%;height:100%;}td,th{padding:4px;border:solid 1px black;text-align:center;}");
        sb.append("\n.left{border-left:none}.right{border-right:none}");
        sb.append("\n</style></head><body><div style=\"text-align:center\">");
        sb.append("\n<h2>Zendesk Failed Job Validation Ticket List</h2><table>");
        sb.append("\n<tr><th>Ticket ID</th><th>Details</th><th>Unknown Job</th><th>Suggestions</th></tr>");
        for (Assignee a:assignees.values()){
          for (BadTicket b:a.problems){
            sg.append("<table>");
            for (i=0;i<b.suggestions.length;++i){
              if (b.suggestions[i]!=null){
                sg.append(format("<tr><td class=\"left\">$0</td><td class=\"right\">$1</td></tr>",
                  escapeHTML(b.suggestions[i].name),
                  b.suggestions[i].active?"Active":"Inactive"
                ));
              }
            }
            sg.append("</table>");
            sb.append(format("\n<tr><td>$0</td><td>$1</td><td>$2</td><td style=\"padding:0\">$3</td></tr>",
              b.ticket.id,
              escapeHTML(b.ticket.org)+"<hr>"+escapeHTML(b.ticket.subject),
              b.badID.length()==b.ticket.jobID.length()?escapeHTML(b.badID):escapeHTML(b.ticket.jobID)+"<hr>"+escapeHTML(b.badID),
              sg
            ));
            sg.setLength(0);
          }
        }
        sb.append("\n</table></div></body></html>");
        Emailer.init();
        Emailer.send("dstclair@automaticcontrols.net,zdhom@automaticcontrols.net", "Zendesk Validation", sb.toString(), true);
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
  public static void findMatches(String s, Collection<String> c, StringMatch[] matches){
    int i,j,k=0,l=-1;
    for (String t:c){
      i = d(s,t);
      if (k<matches.length){
        matches[k].rating = i;
        matches[k].s = t;
        ++k;
      }else{
        if (l==-1){
          l = 0;
          for (j=1;j<matches.length;++j){
            if (matches[j].rating>matches[l].rating){
              l = j;
              break;
            }
          }
        }
        if (i<matches[l].rating){
          matches[l].rating = i;
          matches[l].s = t;
          l = -1;
        }
      }
    }
    Arrays.sort(matches);
  }
  private volatile static int[] buf = new int[81];
  /**
   * @return the optimal string alignment distance between {@code a} and {@code b}.
   */
  public static int d(String a, String b){
    final int aa = a.length()+1;
    final int bb = b.length()+1;
    final int len = aa*bb;
    if (len>buf.length){
      buf = new int[len];
    }
    int i,j,k,x;
    for (i=0;i<aa;++i){
      buf[i] = i;
    }
    for (i=1,j=aa;i<bb;++i,j+=aa){
      buf[j] = i;
    }
    k = aa;
    final int l = 2+(aa<<1);
    for (j=1;j<bb;++j){
      for (i=1,++k;i<aa;++i,++k){
        x = Math.min(buf[k-1],buf[k-aa]);
        if (i>1 && j>1 && a.charAt(i-1)==b.charAt(j-2) && a.charAt(i-2)==b.charAt(j-1)){
          x = Math.min(x, buf[k-l]);
        }
        ++x;
        x = Math.min(x, buf[k-1-aa]+(a.charAt(i-1)==b.charAt(j-1)?0:1));
        buf[k] = x;
      }
    }
    return buf[len-1];
  }
  private final static Pattern formatter = Pattern.compile("\\$(\\d)");
  /**
   * Replaces occurrences of {@code $n} in the input {@code String} with the nth indexed argument.
   * For example, {@code format("Hello $0!", "Beautiful")=="Hello Beautiful!"}.
   */
  public static String format(final String s, final Object... args){
    final String[] args_ = new String[args.length];
    for (int i=0;i<args.length;++i){
      args_[i] = args[i]==null?"":Matcher.quoteReplacement(args[i].toString());
    }
    return formatter.matcher(s).replaceAll(new java.util.function.Function<MatchResult,String>(){
      public String apply(MatchResult m){
        int i = Integer.parseInt(m.group(1));
        return i<args.length?args_[i]:"";
      }
    });
  }
  /**
   * Escapes a {@code String} for usage in HTML attribute values.
   * @param str is the {@code String} to escape.
   * @return the escaped {@code String}.
   */
  public static String escapeHTML(CharSequence str){
    if (str==null){ return ""; }
    int len = str.length();
    StringBuilder sb = new StringBuilder(len+16);
    char c;
    int j;
    for (int i=0;i<len;++i){
      c = str.charAt(i);
      j = c;
      if (j>=32 && j<127){
        switch (c){
          case '&':{
            sb.append("&amp;");
            break;
          }
          case '"':{
            sb.append("&quot;");
            break;
          }
          case '\'':{
            sb.append("&apos;");
            break;
          }
          case '<':{
            sb.append("&lt;");
            break;
          }
          case '>':{
            sb.append("&gt;");
            break;
          }
          default:{
            sb.append(c);
          }
        }
      }else if (j<1114111 && (j<=55296 || j>57343)){
        sb.append("&#").append(Integer.toString(j)).append(";");
      }
    }
    return sb.toString();
  }
}