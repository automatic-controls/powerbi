import java.time.*;
import java.util.*;
public class Contact {
  private volatile Cache cache;
  public volatile int id = -1;
  public volatile String email = null;
  public volatile String first_name = null;
  public volatile String last_name = null;
  public volatile String honorific = null;
  public volatile String title = null;
  public volatile String source = null;
  public volatile String address_1 = null;
  public volatile String address_2 = null;
  public volatile String city = null;
  public volatile String state = null;
  public volatile String zip_code = null;
  public volatile String phone_1 = null;
  public volatile String phone_2 = null;
  public volatile String notes = null;
  public volatile OffsetDateTime last_modified = null;
  public volatile HashSet<String> tags = null;
  public volatile Company company = null;
  private volatile boolean overwrite = true;
  public Contact(Cache cache){
    this.cache = cache;
  }
  public Cache getParent(){
    return cache;
  }
  public void addTags(String[] tags){
    if (tags==null){
      return;
    }
    if (this.tags==null){
      this.tags = new HashSet<String>();
    }
    for (int i=0;i<tags.length;++i){
      this.tags.add(tags[i]);
    }
  }
  public void setPriority(String source){
    overwrite = getValue(source)>=getValue(this.source);
    if (overwrite){
      this.source = source;
    }
  }
  public void setLastModified(OffsetDateTime last_modified){
    if (last_modified!=null && (overwrite || this.last_modified==null)){
      this.last_modified = last_modified;
    }
  }
  public void setName(String first_name, String last_name, String honorific, String title){
    if (first_name!=null && (overwrite || this.first_name==null)){
      this.first_name = first_name;
    }
    if (last_name!=null && (overwrite || this.last_name==null)){
      this.last_name = last_name;
    }
    if (honorific!=null && (overwrite || this.honorific==null)){
      this.honorific = honorific;
    }
    if (title!=null && (overwrite || this.title==null)){
      this.title = title;
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
  public void setNotes(String notes){
    if (notes!=null && (overwrite || this.notes==null)){
      this.notes = notes;
    }
  }
  public Company setCompany(String company){
    if (company!=null && (overwrite || this.company==null)){
      this.company = cache.getCompany(company);
      return this.company;
    }
    return null;
  }
  public static int getValue(String source){
    if (source==null){
      return 0;
    }
    switch (source.toLowerCase()){
      case "outlook": return 4;
      case "pipedrive": return 3;
      case "zendesk": return 2;
      case "mailchimp": return 1;
      default: return 0;
    }
  }
}