import java.sql.*;
import java.util.*;
import java.time.*;
import java.nio.file.*;
public class Connector implements AutoCloseable {
  private volatile static String mailchimpQuery = null;
  private volatile Connection con = null;
  public void sync() throws Throwable {
    for (int i=1;i<=Env.attempts;++i){
      try{
        if (mailchimpQuery==null){
          mailchimpQuery = new String(Files.readAllBytes(Paths.get(Main.class.getProtectionDomain().getCodeSource().getLocation().toURI()).getParent().resolve("queries").resolve("mailchimp.sql")), java.nio.charset.StandardCharsets.UTF_8);
        }
        final Cache cache = new Cache();
        ensureConnect();
        try(
          Statement s = con.createStatement();
        ){
          final HashSet<String> emails = new HashSet<String>();
          try(
            ResultSet r = s.executeQuery("SELECT LOWER(\"email\") FROM contacts.contacts WHERE \"override\";");
          ){
            while (r.next()){
              emails.add(r.getString(1));
            }
          }
          try(
            ResultSet r = s.executeQuery(mailchimpQuery);
          ){
            String email;
            Contact c;
            Company cc;
            OffsetDateTime d;
            while (r.next()){
              email = r.getString(1);
              if (!emails.contains(email)){
                c = cache.getContact(email);
                c.setPriority("mailchimp");
                c.setName(r.getString(2), r.getString(3), null, r.getString(4));
                c.setAddress(r.getString(6), r.getString(7), r.getString(8), r.getString(9), r.getString(10));
                c.setPhone(r.getString(11), r.getString(12));
                d = r.getObject(14, OffsetDateTime.class);
                c.setLastModified(d);
                c.addTags((String[])r.getArray(13).getArray());
                cc = c.setCompany(r.getString(5));
                if (cc!=null){
                  cc.setPriority("mailchimp");
                  cc.setLastModified(d);
                }
              }
            }
          }
          //*
          try(
            ResultSet r = s.executeQuery("SELECT \"a\".\"id\", \"a\".\"email\", \"b\".\"id\", \"b\".\"name\", \"b\".\"override\" FROM contacts.contacts \"a\" LEFT JOIN contacts.companies \"b\" ON \"a\".\"company_id\" = \"b\".\"id\";");
          ){

          }
          //*/
        }

        // collect all emails from contacts.contacts where override is true
        // retrieve and cache results from all sources
        //   ignore any contacts from the override=true list gathered in the previous step
        //   combine the results into a single cache as you gather them
        //   this should include companies and tags
        //   there should be no duplicate emails
        //   when an email exists in more than one source, choose the entry with highest source priority and merge data accordingly
        //   two companies are considered the same if they have the same name (case-insensitive)
        //   if any source fails to query, abort the whole procedure
        // collect all tuples (id, email, company_id, company_name, company_override) from contacts.contacts where override is false
        // for each email, if it doesn't exist in the query cache, delete it from contacts.contacts and the collected email list
        //   do not delete from contacts.tags or contacts.companies in this step
        // 
        // for each remaining collected email, overwrite all existing data with the query cache (and clear these cached entries afterwards)
        //   this includes overwriting tags
        //   the company should only be overwritten if the existing is either null or has override=false
        //     if override=true, do not touch the company
        //     if override=false and the company names do not match, create a new company with the new name (assuming one does not already exist)
        //     if override=false and the company name matches, update the existing company.
        // for each remaining cached result, add it to contact.contacts
        //   this includes creating relevant tags
        //   if a company of the same name already exists and override=true, then set it
        //   if a company of the same name already exists and override=false, then merge the company information according to rules in the first step

        // delete each tag where the associated contact is invalid (deleted)
        // delete each company where override is false and there are zero associated contacts
        // clear the primary_contact field of companies when it is invalid (referring to a deleted contact)

        try(
          PreparedStatement s = con.prepareStatement("INSERT INTO contacts.companies (\"id\", \"name\", \"archived\", \"override\", \"last_modified\", \"source\") VALUES (DEFAULT, ?, FALSE, FALSE, ?, ?) RETURNING \"id\";");
        ){
          for (Company c:cache.companies.values()){
            s.setString(1, c.name);
            s.setObject(2, c.last_modified);
            s.setString(3, c.source);
            try(
              ResultSet r = s.executeQuery();
            ){
              if (r.next()){
                c.id = r.getInt(1);
              }
            }
          }
        }
        try(
          PreparedStatement s = con.prepareStatement("INSERT INTO contacts.contacts VALUES (DEFAULT,?,?,?,?,?,?,FALSE,?,?,?,?,?,?,?,?,?,FALSE,?) RETURNING \"id\";");
        ){
          for (Contact c:cache.contacts.values()){
            if (c.company==null){
              s.setNull(1, Types.INTEGER);
            }else{
              s.setInt(1, c.company.id);
            }
            s.setString(2, c.email);
            s.setString(3, c.first_name);
            s.setString(4, c.last_name);
            s.setString(5, c.honorific);
            s.setString(6, c.title);
            s.setString(7, c.source);
            s.setString(8, c.address_1);
            s.setString(9, c.address_2);
            s.setString(10, c.city);
            s.setString(11, c.state);
            s.setString(12, c.zip_code);
            s.setString(13, c.phone_1);
            s.setString(14, c.phone_2);
            s.setString(15, c.notes);
            s.setObject(16, c.last_modified);
            try(
              ResultSet r = s.executeQuery();
            ){
              if (r.next()){
                c.id = r.getInt(1);
              }
            }
          }
        }
        try(
          PreparedStatement s = con.prepareStatement("INSERT INTO contacts.tags VALUES (?,?);");
        ){
          for (Contact c:cache.contacts.values()){
            s.setInt(1,c.id);
            for (String tag:c.tags){
              s.setString(2,tag);
              s.addBatch();
            }
          }
          s.executeBatch();
        }
        con.commit();
        
      }catch(Throwable t){
        if (i==Env.attempts){
          throw t;
        }
        Thread.sleep(30000L);
      }
    }
  }
  private void ensureConnect() throws SQLException {
    if (con!=null && !con.isValid(3000)){
      con.close();
      con = null;
    }
    if (con==null || con.isClosed()){
      con = DriverManager.getConnection("jdbc:postgresql://"+Env.postgresql_url+":"+Env.postgresql_port+"/"+Env.postgresql_database, Env.postgresql_user, Env.postgresql_pass);
      con.setAutoCommit(false);
    }
  }
  @Override public void close() throws SQLException {
    if (con!=null){
      con.close();
    }
  }
}