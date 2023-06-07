import java.net.*;
import java.nio.charset.*;
import javax.net.ssl.*;
import java.util.*;
import java.util.regex.*;
import java.time.*;
import java.time.format.*;
import com.google.gson.*;
import java.io.*;
public class TimeCardAPI {
  private static String TODAY = null;
  private static String ONE_WEEK_AGO = null;
  private static String TWO_WEEKS_AGO = null;
  static {
    LocalDate d = LocalDate.now();
    //Jump to the nearest Saturday in the future
    d = d.plusDays(6-(d.getDayOfWeek().getValue()%7));
    TODAY = DateTimeFormatter.ISO_LOCAL_DATE.format(d);
    d = d.plusDays(-7);
    ONE_WEEK_AGO = DateTimeFormatter.ISO_LOCAL_DATE.format(d);
    d = d.plusDays(-13);
    TWO_WEEKS_AGO = DateTimeFormatter.ISO_LOCAL_DATE.format(d);
  }
  private final static CharsetDecoder jsonDecoder = java.nio.charset.StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.IGNORE).onUnmappableCharacter(CodingErrorAction.IGNORE);
  private final static int timeout = 30000;
  private final static String authURL = "https://clock.payrollservers.us/AuthenticationService/oauth2/usertoken";
  private final static String apiURL = "https://twpapi.payrollservers.us/api/"+Env.twp_site_id;
  private final static String employeeURL = apiURL+"/employees?beginEffectiveDate="+TWO_WEEKS_AGO+"&endEffectiveDate="+TODAY+"&onlyActive=false";
  private final static String timecardURL = apiURL+"/timecards?periodDate=$0&ids=$1";
  private final static Pattern tokenParser = Pattern.compile("\"token\"\\s*+:\\s*+\"([^\"]++)\"");
  private final static Pattern employeeCodeParser = Pattern.compile("\"EmployeeCode\"\\s*+:\\s*+\"([^\"]++)\"");
  private String token = null;
  private long tokenExpiration = -1;
  private java.sql.Date startDate;
  private java.sql.Date endDate;
  private String employeeName;
  public TimeCardAPI() throws Throwable {
    try(
      final DataUploader up = new DataUploader();
    ){
      final HashSet<String> employees = getEmployees();
      up.deleteUnlistedEmployees(employees, java.sql.Date.valueOf(TWO_WEEKS_AGO), java.sql.Date.valueOf(TODAY));
      ArrayList<TimecardEntry> entries;
      for (String code:employees){
        entries = getTimecard(code, TODAY);
        up.submit(entries, startDate, endDate, code, employeeName);
        entries = getTimecard(code, ONE_WEEK_AGO);
        up.submit(entries, startDate, endDate, code, employeeName);
        entries = getTimecard(code, TWO_WEEKS_AGO);
        up.submit(entries, startDate, endDate, code, employeeName);
      }
    }
  }
  private ArrayList<TimecardEntry> getTimecard(String employeeCode, String date) throws Throwable {
    generateToken();
    final URL url = new URL(Utility.format(timecardURL, date, employeeCode));
    Throwable e = null;
    final ArrayList<TimecardEntry> entries = new ArrayList<TimecardEntry>(64);
    int code;
    for (int i=0;i<Env.attempts;++i){
      try{
        char[] json;
        final HttpsURLConnection con = (HttpsURLConnection)url.openConnection();
        try{
          con.setConnectTimeout(timeout);
          con.setReadTimeout(timeout);
          con.setRequestMethod("GET");
          con.setRequestProperty("Content-Type", "application/json");
          con.setRequestProperty("Authorization", "Bearer "+token);
          con.setInstanceFollowRedirects(false);
          con.setUseCaches(false);
          con.connect();
          code = con.getResponseCode();
          if (code==200){
            json = jsonDecoder.decode(java.nio.ByteBuffer.wrap(con.getInputStream().readAllBytes())).array();
          }else{
            entries.clear();
            if (code==401){
              tokenExpiration = -1;
            }else if (code==429){
              Thread.sleep(60000L);
            }else{
              Thread.sleep(30000L);
            }
            generateToken();
            continue;
          }
        }finally{
          con.disconnect();
        }
        int len;
        for (len=json.length;len>0;){
          if ((int)json[--len]!=0){
            break;
          }
        }
        ++len;
        final _Root root = new Gson().fromJson(new CharArrayReader(json,0,len), _Root.class);
        json = null;
        startDate = java.sql.Date.valueOf(root.PayPeriodBeginDate);
        endDate = java.sql.Date.valueOf(root.PayPeriodEndDate);
        _TimeCard timecard;
        _Date dateEntries;
        TimecardEntry te;
        for (int j=0,k,l;j<root.TimeCards.length;++j){
          timecard = root.TimeCards[j];
          if (employeeCode.equalsIgnoreCase(timecard.Employee.EmployeeCode)){
            employeeName = timecard.Employee.LastName+", "+timecard.Employee.FirstName;
            for (k=0;k<timecard.Dates.length;++k){
              dateEntries = timecard.Dates[k];
              for (l=0;l<dateEntries.Lines.length;++l){
                te = dateEntries.Lines[l].parse();
                te.setDate(dateEntries.Date.Value);
                entries.add(te);
              }
            }
          }
        }
        e = null;
        break;
      }catch(Throwable ee){
        entries.clear();
        e = ee;
        if (i+1<Env.attempts){
          Thread.sleep(30000L);
        }
      }
    }
    if (e!=null){
      throw e;
    }
    return entries;
  }
  private HashSet<String> getEmployees() throws Throwable {
    generateToken();
    final URL url = new URL(employeeURL);
    Throwable e = null;
    final HashSet<String> employees = new HashSet<String>(64);
    int code = 0;
    for (int i=0;i<Env.attempts;++i){
      try{
        String json;
        final HttpsURLConnection con = (HttpsURLConnection)url.openConnection();
        try{
          con.setConnectTimeout(timeout);
          con.setReadTimeout(timeout);
          con.setRequestMethod("GET");
          con.setRequestProperty("Content-Type", "application/json");
          con.setRequestProperty("Authorization", "Bearer "+token);
          con.setInstanceFollowRedirects(false);
          con.setUseCaches(false);
          con.connect();
          code = con.getResponseCode();
          if (code==200){
            json = new String(con.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
          }else{
            employees.clear();
            if (code==401){
              tokenExpiration = -1;
            }else if (code==429){
              Thread.sleep(60000L);
            }else{
              Thread.sleep(30000L);
            }
            generateToken();
            continue;
          }
        }finally{
          con.disconnect();
        }
        final Matcher m = employeeCodeParser.matcher(json);
        while (m.find()){
          employees.add(m.group(1));
        }
        e = null;
        break;
      }catch(Throwable ee){
        employees.clear();
        e = ee;
        if (i+1<Env.attempts){
          Thread.sleep(30000L);
        }
      }
    }
    if (e!=null){
      throw e;
    }else if (employees.isEmpty()){
      throw new NullPointerException("Failed to load employees (code "+code+").");
    }
    return employees;
  }
  private void generateToken() throws Throwable {
    final long t = System.currentTimeMillis();
    if (t>=tokenExpiration){
      token = null;
      Throwable e = null;
      final URL url = new URL(authURL);
      for (int i=0;i<Env.attempts;++i){
        try{
          tokenExpiration = System.currentTimeMillis()+180000;
          String tok = Utility.base64UrlEncode("{\"typ\":\"JWT\",\"alg\":\"HS256\"}")+'.'+Utility.base64UrlEncode(Utility.format(
            "{\"iss\":$0,\"sub\":\"client\",\"exp\":$1,\"product\":\"twpclient\",\"siteInfo\":{\"type\":\"id\",\"id\":\"$0\"}}",
            Env.twp_site_id,
            tokenExpiration/1000+60
          ));
          tok = tok+'.'+Utility.HMACSHA256(tok, Env.twp_api_secret);
          final HttpsURLConnection con = (HttpsURLConnection)url.openConnection();
          try{
            con.setConnectTimeout(timeout);
            con.setReadTimeout(timeout);
            con.setRequestMethod("POST");
            con.setRequestProperty("Content-Type", "application/json");
            con.setRequestProperty("Authorization", "Bearer "+tok);
            con.setInstanceFollowRedirects(false);
            con.setUseCaches(false);
            con.connect();
            final int code = con.getResponseCode();
            if (code==200 || code==201){
              token = new String(con.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
            }else{
              token = null;
              if (code==429){
                Thread.sleep(60000L);
              }
            }
          }finally{
            con.disconnect();
          }
          if (token!=null){
            final Matcher m = tokenParser.matcher(token);
            if (m.find()){
              token = m.group(1);
            }else{
              token = null;
            }
          }
          e = null;
          if (token!=null){
            break;
          }
        }catch(Throwable ee){
          e = ee;
          if (i+1<Env.attempts){
            Thread.sleep(30000L);
          }
        }
      }
      if (e!=null){
        throw e;
      }else if (token==null){
        throw new NullPointerException("'token' is null. An unexpected error has occurred.");
      }
    }
  }
}