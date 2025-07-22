public class Env {
  public final static String pbi_email = System.getenv("pbi_email");
  public final static String email_tenant_id = System.getenv("email_tenant_id");
  public final static String email_app_id = System.getenv("email_app_id");
  public final static String email_keystore = System.getenv("email_keystore");
  public final static String email_keystore_password = System.getenv("email_keystore_password");
  public final static String postgresql_url = System.getenv("postgresql_url");
  public final static String postgresql_port = System.getenv("postgresql_port");
  public final static String postgresql_database = System.getenv("postgresql_database");
  public final static String postgresql_user = System.getenv("postgresql_user");
  public final static String postgresql_pass = System.getenv("postgresql_pass");
  public final static int attempts = getAttempts();
  public final static boolean bad =
       pbi_email==null
    || email_tenant_id==null
    || email_app_id==null
    || email_keystore==null
    || email_keystore_password==null
    || postgresql_url==null
    || postgresql_port==null
    || postgresql_database==null
    || postgresql_user==null
    || postgresql_pass==null
    || attempts==0;
  private static int getAttempts(){
    try{
      return Integer.parseInt(System.getenv("attempts"));
    }catch(Throwable t){
      return 0;
    }
  }
}