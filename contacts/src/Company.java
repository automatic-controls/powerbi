import java.time.*;
public class Company {
  private volatile Cache cache;
  public volatile int id = -1;
  public volatile String name = null;
  public volatile String source = null;
  public volatile String address_1 = null;
  public volatile String address_2 = null;
  public volatile String city = null;
  public volatile String state = null;
  public volatile String zip_code = null;
  public volatile String phone_1 = null;
  public volatile String phone_2 = null;
  public volatile String future_revenue_class = null;
  public volatile String risk_level = null;
  public volatile String vertical = null;
  public volatile String notes = null;
  public volatile OffsetDateTime last_modified = null;
  private volatile boolean overwrite = true;
  public Company(Cache cache){
    this.cache = cache;
  }
  public Cache getParent(){
    return cache;
  }
  public void setPriority(String source){
    overwrite = Contact.getValue(source)>=Contact.getValue(this.source);
    if (overwrite){
      this.source = source;
    }
  }
  public void setLastModified(OffsetDateTime last_modified){
    if (last_modified!=null && (overwrite || this.last_modified==null)){
      this.last_modified = last_modified;
    }
  }
  public void setAddress(String address_1, String address_2, String city, String state, String zip_code){
    if (address_1!=null && (overwrite || this.address_1==null)){
      this.address_1 = address_1;
    }
    if (address_2!=null && (overwrite || this.address_2==null)){
      this.address_2 = address_2;
    }
    if (city!=null && (overwrite || this.city==null)){
      this.city = city;
    }
    if (state!=null && (overwrite || this.state==null)){
      this.state = state;
    }
    if (zip_code!=null && (overwrite || this.zip_code==null)){
      this.zip_code = zip_code;
    }
  }
  public void setPhone(String phone_1, String phone_2){
    boolean use2 = true;
    if (phone_1!=null){
      if (this.phone_1==null){
        this.phone_1 = phone_1;
      }else if (!phone_1.equals(this.phone_1)){
        if (this.phone_2==null){
          this.phone_2 = phone_1;
          use2 = false;
        }else if (phone_1.equals(this.phone_2)){
          use2 = false;
        }else if (overwrite){
          this.phone_1 = phone_1;
        }
      }
    }
    if (use2 && phone_2!=null && (overwrite || this.phone_2==null)){
      this.phone_2 = phone_2;
    }
  }
  public void setMisc(String future_revenue_class, String risk_level, String vertical){
    if (future_revenue_class!=null && (overwrite || this.future_revenue_class==null)){
      this.future_revenue_class = future_revenue_class;
    }
    if (risk_level!=null && (overwrite || this.risk_level==null)){
      this.risk_level = risk_level;
    }
    if (vertical!=null && (overwrite || this.vertical==null)){
      this.vertical = vertical;
    }
  }
  public void setNotes(String notes){
    if (notes!=null && (overwrite || this.notes==null)){
      this.notes = notes;
    }
  }
}