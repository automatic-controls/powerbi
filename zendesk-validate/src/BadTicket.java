public class BadTicket {
  public volatile Ticket ticket;
  public volatile String badID;
  public volatile Job[] suggestions;
  public BadTicket(Ticket ticket, String badID){
    this.ticket = ticket;
    this.badID = badID;
  }
}