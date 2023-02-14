import java.math.BigDecimal;
import java.sql.*;
import java.util.regex.*;
public class Job {
  private final static Pattern idParser = Pattern.compile("^[a-zA-Z]\\w*+(?:-\\w++)++\\b");
  private final static Pattern numParser = Pattern.compile("-?+\\d++(?:,\\d{3}+)*+(?:\\.\\d{1,2}+)?+");
  private final static Pattern positiveNumParser = Pattern.compile("\\d++(?:,\\d{3}+)*+(?:\\.\\d{1,2}+)?+");
  public static volatile int count = 0;
  public String id = null;
  public String name = null;
  public Timestamp creationTime = null;
  public String proposalPrice = null;
  public String changeOrders = null;
  public String contractPrice = null;
  public String billedToDate = null;
  public String previousInvoices = null;
  public Job(String name, Timestamp creationTime, String proposalPrice, String changeOrders, String contractPrice, String billedToDate, String previousInvoices){
    this.name = name;
    this.creationTime = creationTime;
    this.proposalPrice = proposalPrice;
    this.changeOrders = changeOrders;
    this.contractPrice = contractPrice;
    this.billedToDate = billedToDate;
    this.previousInvoices = previousInvoices;
    if (name==null){
      System.out.println("Job ID: "+name);
      ++count;
    }else if (!name.startsWith("DO NOT USE ")){
      Matcher m = idParser.matcher(name);
      if (m.find()){
        id = m.group();
      }else{
        System.out.println("Job ID: "+name);
        ++count;
      }
    }
  }
  public void validate(){
    boolean fucked = proposalPrice==null || changeOrders==null || contractPrice==null;
    if (proposalPrice!=null && !positiveNumParser.matcher(proposalPrice).matches()){
      System.out.println(id+" Proposal Price: "+proposalPrice);
      ++count;
      fucked = true;
    }
    if (changeOrders!=null && !numParser.matcher(changeOrders).matches()){
      System.out.println(id+" Change Orders: "+changeOrders);
      ++count;
      fucked = true;
    }
    if (contractPrice!=null && !positiveNumParser.matcher(contractPrice).matches()){
      System.out.println(id+" Contract Price: "+contractPrice);
      ++count;
      fucked = true;
    }
    if (billedToDate!=null && !positiveNumParser.matcher(billedToDate).matches()){
      System.out.println(id+" Billed To Date: "+billedToDate);
      ++count;
    }
    if (previousInvoices!=null && !positiveNumParser.matcher(previousInvoices).matches()){
      System.out.println(id+" Previous Invoices: "+previousInvoices);
      ++count;
    }
    if (!fucked){
      try{
        fucked = new BigDecimal(proposalPrice.replace(",","")).add(new BigDecimal(changeOrders.replace(",",""))).compareTo(new BigDecimal(contractPrice.replace(",","")))!=0;
      }catch(Throwable t){
        fucked = true;
      }
      if (fucked){
        System.out.println(id+": "+proposalPrice+(changeOrders.startsWith("-")?"":"+")+changeOrders+" != "+contractPrice);
      }
    }
  }
}