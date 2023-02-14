public class Env {
  public final static String pbi_email = System.getenv("pbi_email");
  public final static String pbi_password = System.getenv("pbi_password");
  public final static String postgresql_url = System.getenv("postgresql_url");
  public final static String postgresql_user = System.getenv("postgresql_user");
  public final static String postgresql_pass = System.getenv("postgresql_pass");
  public final static boolean bad =
       pbi_email==null
    || pbi_password==null
    || postgresql_url==null
    || postgresql_user==null
    || postgresql_pass==null;
}