import java.util.*;
import com.azure.identity.*;
import com.microsoft.graph.models.*;
import com.microsoft.graph.serviceclient.*;
import com.microsoft.graph.users.item.sendmail.SendMailPostRequestBody;
public class Emailer {
  private volatile static String[] scopes;
  private volatile static ClientCertificateCredential cred;
  private volatile static GraphServiceClient client = null;
  public static void init() throws Throwable {
    scopes = new String[]{"https://graph.microsoft.com/.default"};
    cred = new ClientCertificateCredentialBuilder()
      .clientId(Env.email_app_id)
      .tenantId(Env.email_tenant_id)
      .pfxCertificate(Env.email_keystore)
      .clientCertificatePassword(Env.email_keystore_password)
      .build();
  }
  public static void send(String recipients, String subject, String content, boolean html) throws Throwable {
    if (client==null){
      client = new GraphServiceClient(cred, scopes);
    }
    String[] recips = recipients.split(",");
    ArrayList<Recipient> recipientList = new ArrayList<>(recips.length);
    for (String email : recips) {
      Recipient recipient = new Recipient();
      EmailAddress emailAddress = new EmailAddress();
      emailAddress.setAddress(email.trim());
      recipient.setEmailAddress(emailAddress);
      recipientList.add(recipient);
    }
    final Message msg = new Message();
    msg.setSubject(subject);
    msg.setToRecipients(recipientList);
    final ItemBody body = new ItemBody();
    body.setContentType(html ? BodyType.Html : BodyType.Text);
    body.setContent(content);
    msg.setBody(body);
    final SendMailPostRequestBody sendMailBody = new SendMailPostRequestBody();
    sendMailBody.setMessage(msg);
    sendMailBody.setSaveToSentItems(false);
    client.users().byUserId(Env.pbi_email).sendMail().post(sendMailBody);
  }
}