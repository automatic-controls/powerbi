import java.util.*;
public class Cache {
  public final HashMap<String,Contact> contacts = new HashMap<String,Contact>();
  public final HashMap<String,Company> companies = new HashMap<String,Company>();
  public Contact getContact(String email){
    final String s = email.toLowerCase();
    Contact c = contacts.get(s);
    if (c==null){
      c = new Contact(this);
      c.email = email;
      contacts.put(s,c);
    }
    return c;
  }
  public Company getCompany(String name){
    final String s = name.toLowerCase();
    Company c = companies.get(s);
    if (c==null){
      c = new Company(this);
      c.name = name;
      companies.put(s,c);
    }
    return c;
  }
}