public class Env {
  public final static String asana_token = System.getenv("asana_token");
  public final static String postgresql_url = System.getenv("postgresql_url");
  public final static String postgresql_user = System.getenv("postgresql_user");
  public final static String postgresql_pass = System.getenv("postgresql_pass");
  public final static boolean bad =
       asana_token==null
    || postgresql_url==null
    || postgresql_user==null
    || postgresql_pass==null;
}