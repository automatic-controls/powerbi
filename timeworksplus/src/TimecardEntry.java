import java.sql.Date;
public class TimecardEntry {
  public String pay_type = null;
  public String job = null;
  public String work_category = null;
  public int seconds = -1;
  public String notes = null;
  public Date date = null;
  public void setDate(String date) throws IllegalArgumentException {
    this.date = Date.valueOf(date);
  }
  public @Override String toString(){
    return date+", "+pay_type+", "+job+", "+work_category+", "+(seconds/3600.0)+", "+notes;
  }
}