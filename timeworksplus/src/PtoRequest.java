import java.time.*;
import java.time.format.DateTimeParseException;
import java.sql.Date;
public class PtoRequest implements Comparable<PtoRequest> {
  public OffsetDateTime created_at = null;
  public String category = null;
  public Date date = null;
  public double hours = -1;
  public String status = null;
  public String approved_by = null;
  public OffsetDateTime approved_at = null;
  public String comments = null;
  public void setDate(String date) throws IllegalArgumentException {
    final int i = date.indexOf('T');
    if (i!=-1){
      date = date.substring(0,i);
    }
    this.date = Date.valueOf(date);
  }
  public void setCreatedAt(String time) throws DateTimeParseException {
    created_at = OffsetDateTime.of(LocalDateTime.parse(time), ZoneOffset.UTC);
  }
  public void setApprovedAt(String time) throws DateTimeParseException {
    if (time==null){ return; }
    approved_at = OffsetDateTime.of(LocalDateTime.parse(time), ZoneOffset.UTC);
  }
  @Override public int compareTo(PtoRequest req){
    if (date==null){
      return req.date==null?0:-1;
    }else{
      return req.date==null?1:date.compareTo(req.date);
    }
  }
}