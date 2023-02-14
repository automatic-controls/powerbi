import java.util.Properties;
import jakarta.mail.*;
import jakarta.mail.internet.*;
public class Emailer {
  private volatile static Session s;
  private volatile static InternetAddress from;
  public static void init() throws Throwable {
    final Properties props = new Properties();
    props.setProperty("mail.smtp.auth", "true");
    props.setProperty("mail.smtp.starttls.enable", "true");
    props.setProperty("mail.smtp.ssl.protocols", "TLSv1.2");
    props.setProperty("mail.smtp.host", "smtp-mail.outlook.com");
    props.setProperty("mail.smtp.port", "587");
    s = Session.getInstance(props, new Authenticator(){
      @Override protected PasswordAuthentication getPasswordAuthentication(){
        return new PasswordAuthentication(Env.pbi_email, Env.pbi_password);
      }
    });
    from = new InternetAddress(Env.pbi_email);
  }
  public static void send(String recipients, String subject, String content, boolean html) throws Throwable {
    final MimeMessage message = new MimeMessage(s);
    message.setFrom(from);
    message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(recipients));
    message.setSubject(subject);
    message.setText(content, "UTF-8", html?"html":"plain");
    Transport.send(message);
  }
}