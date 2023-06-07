import com.google.gson.*;
public class _Line {
  public String BaseCategoryR;
  public String Seconds;
  public _Comment[] EditEvents;
  public _Variables Variables;
  public TimecardEntry parse(){
    final TimecardEntry e = new TimecardEntry();
    e.pay_type = BaseCategoryR;
    if (e.pay_type==null){
      e.pay_type = "Regular";
    }
    e.job = Variables.get("Job");
    if (e.job==null){
      e.job = "01-Office Time Overhead";
    }
    e.work_category = Variables.get("WorkCategory");
    if (e.work_category==null){
      e.work_category = "NO CATEGORY SELECTED";
    }
    String s = Variables.get("SECONDS");
    if (s==null){
      s = Seconds;
    }
    if (s==null){
      return null;
    }
    try{
      e.seconds = Integer.parseInt(s);
    }catch(NumberFormatException t){
      return null;
    }
    final JsonArray arr = new JsonArray(EditEvents.length);
    for (int i=0;i<EditEvents.length;++i){
      s = EditEvents[i].EditComment;
      if (s!=null && !s.isBlank()){
        arr.add(s);
      }
    }
    e.notes = new Gson().toJson(arr);
    if (e.notes==null){
      e.notes = "[]";
    }
    return e;
  }
}