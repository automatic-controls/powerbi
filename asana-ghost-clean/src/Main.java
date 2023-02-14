import java.sql.*;
import com.asana.*;
import com.asana.models.*;
import com.asana.requests.*;
import java.util.*;
import java.text.DecimalFormat;
import java.time.*;
import java.time.format.*;
public class Main {
  public final static DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm:ss").withZone(ZoneId.systemDefault());
  public final static long WORKSPACE_GID = 155477067182454L;
  public final static long LIMIT = 10000000L;
  public static int projectCount = -1;
  public static long[] projectGids;
  public static byte[] projectFlags;
  public static int taskCount = -1;
  public static long[] taskGids;
  public static byte[] taskFlags;
  public static void main(String[] args){
    System.exit(exec()?0:1);
  }
  public static boolean exec(){
    try{
      final long startTime = System.currentTimeMillis();
      System.out.println("Application initialized at "+DATE_FORMATTER.format(Instant.ofEpochMilli(startTime)));
      if (Env.bad){
        System.out.println("Required environment variable(s) not defined.");
        return false;
      }
      System.out.println("Establishing connection to database...");
      try(
        Connection con = DriverManager.getConnection("jdbc:postgresql://"+Env.postgresql_url+":5432/analytics", Env.postgresql_user, Env.postgresql_pass);
      ){
        con.setAutoCommit(false);
        try{
          System.out.println("Retrieving project count from database...");
          try(
            Statement s = con.createStatement();
          ){
            try(
              ResultSet r = s.executeQuery("SELECT COUNT(*) FROM asana_v2.projects;");
            ){
              if (r.next()){
                long l = r.getLong(1);
                if (l>LIMIT){
                  System.out.println("Returned project count exceeds limit: "+l+'>'+LIMIT);
                  return false;
                }else{
                  projectCount = (int)l;
                }
              }
            }
            if (projectCount==-1){
              System.out.println("Failed to retrieve project count.");
              return false;
            }
            System.out.println("Found "+projectCount+" project(s).");
            projectGids = new long[projectCount];
            System.out.println("Retrieving project gids from database...");
            try(
              ResultSet r = s.executeQuery("SELECT gid::BIGINT FROM asana_v2.projects;");
            ){
              int i=0;
              while (i<projectCount && r.next()){
                projectGids[i] = r.getLong(1);
                ++i;
              }
              projectCount = i;
            }
          }
          con.commit();
          Arrays.sort(projectGids,0,projectCount);
          projectFlags = new byte[projectCount];
          Arrays.fill(projectFlags,(byte)0);
          System.out.println("Establishing connection to Asana...");
          Client cl = Client.accessToken(Env.asana_token);
          {
            int i;
            System.out.println("Retrieving projects from Asana...");
            CollectionRequest<Project> req = cl.projects.findAll().query("workspace",WORKSPACE_GID).query("opt_fields",new String[]{"gid"});
            for (Project p:req){
              i = Arrays.binarySearch(projectGids, 0, projectCount, Long.parseLong(p.gid));
              if (i>=0){
                projectFlags[i] = 1;
              }
            }
            req = null;
            ArrayList<Long> gidsToDelete = new ArrayList<Long>();
            for (i=0;i<projectCount;++i){
              if (projectFlags[i]==0){
                gidsToDelete.add(projectGids[i]);
              }
            }
            int deleteSize = gidsToDelete.size();
            if (deleteSize>0){
              System.out.println("Deleting "+deleteSize+" ghost project(s) from database...");
              final String query = 
              "DO $$\n"+
              "  DECLARE\n"+
              "    gids text[] := ARRAY[?];\n"+
              "  BEGIN\n"+
              "    DELETE FROM asana_v2.projects WHERE gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.projects__custom_fields WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.projects__custom_fields__enum_options WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.projects__followers WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.projects__members WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__projects WHERE gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.sections WHERE project__gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.portfolios__portfolio_items WHERE resource_type='project' AND gid=ANY(gids);\n"+
              "  END;\n"+
              "$$;";
              try(
                Statement s = con.createStatement();
              ){
                i = 0;
                int j;
                StringBuilder sb = new StringBuilder();
                while (i<deleteSize){
                  for (j=0;j<50 && i<deleteSize;++j,++i){
                    if (j!=0){
                      sb.append(',');
                    }
                    sb.append('\'');
                    sb.append(gidsToDelete.get(i));
                    sb.append('\'');
                  }
                  if (j>0){
                    s.addBatch(query.replace("?",sb.toString()));
                    sb.setLength(0);
                  }
                }
                int[] results = s.executeBatch();
                for (i=0;i<results.length;++i){
                  if (results[i]==Statement.EXECUTE_FAILED){
                    System.out.println("An error occurred while deleting projects from database.");
                    return false;
                  }
                }
              }
              con.commit();
              System.out.println("Successfully removed ghost project(s) from database.");
            }else{
              System.out.println("No ghost projects exist in database.");
            }
          }
          System.out.println("Retrieving task count from database...");
          try(
            Statement s = con.createStatement();
          ){
            try(
              ResultSet r = s.executeQuery("SELECT COUNT(*) FROM asana_v2.tasks;");
            ){
              if (r.next()){
                long l = r.getLong(1);
                if (l>LIMIT){
                  System.out.println("Returned task count exceeds limit: "+l+'>'+LIMIT);
                  return false;
                }else{
                  taskCount = (int)l;
                }
              }
            }
            if (taskCount==-1){
              System.out.println("Failed to retrieve task count.");
              return false;
            }
            System.out.println("Found "+taskCount+" task(s).");
            taskGids = new long[taskCount];
            System.out.println("Retrieving task gids from database...");
            try(
              ResultSet r = s.executeQuery("SELECT gid::BIGINT FROM asana_v2.tasks;");
            ){
              int i=0;
              while (i<taskCount && r.next()){
                taskGids[i] = r.getLong(1);
                ++i;
              }
              taskCount = i;
            }
          }
          con.commit();
          Arrays.sort(taskGids,0,taskCount);
          taskFlags = new byte[taskCount];
          Arrays.fill(taskFlags,(byte)0);
          System.out.println("Retrieving task gids from Asana...");
          {
            int i;
            CollectionRequest<Task> req;
            int percent = 5;
            for (int k=0;k<projectCount;++k){
              if (projectFlags[k]==1){
                try{
                  req = cl.tasks.findAll().query("project",projectGids[k]).query("opt_fields",new String[]{"gid"});
                  for (Task t:req){
                    i = Arrays.binarySearch(taskGids, 0, taskCount, Long.parseLong(t.gid));
                    if (i>=0){
                      taskFlags[i] = 1;
                    }
                  }
                }catch(NoSuchElementException e){
                  // Probably failed because the project GID no longer exists in Asana
                  // So we ignore such errors
                }
                req = null;
              }
              if ((k+1)*100/projectCount>=percent){
                //System.out.println(percent+"%");
                percent+=5;
              }
            }
            ArrayList<Long> gidsToDelete = new ArrayList<Long>();
            for (i=0;i<taskCount;++i){
              if (taskFlags[i]==0){
                gidsToDelete.add(taskGids[i]);
              }
            }
            int deleteSize = gidsToDelete.size();
            if (deleteSize>0){
              System.out.println("Deleting "+deleteSize+" ghost task(s) from database...");
              final String query =
              "DO $$\n"+
              "  DECLARE\n"+
              "    gids text[] := ARRAY[?];\n"+
              "  BEGIN\n"+
              "    DELETE FROM asana_v2.tasks WHERE gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__custom_fields WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__custom_fields__enum_options WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__dependencies WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__dependents WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__followers WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__hearts WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__likes WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__memberships WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__projects WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "    DELETE FROM asana_v2.tasks__tags WHERE _sdc_source_key_gid=ANY(gids);\n"+
              "  END;\n"+
              "$$;";
              try(
                Statement s = con.createStatement();
              ){
                i = 0;
                int j;
                StringBuilder sb = new StringBuilder();
                while (i<deleteSize){
                  for (j=0;j<50 && i<deleteSize;++j,++i){
                    if (j!=0){
                      sb.append(',');
                    }
                    sb.append('\'');
                    sb.append(gidsToDelete.get(i));
                    sb.append('\'');
                  }
                  if (j>0){
                    s.addBatch(query.replace("?",sb.toString()));
                    sb.setLength(0);
                  }
                }
                int[] results = s.executeBatch();
                for (i=0;i<results.length;++i){
                  if (results[i]==Statement.EXECUTE_FAILED){
                    System.out.println("An error occurred while deleting tasks from database.");
                    return false;
                  }
                }
              }
              con.commit();
              System.out.println("Successfully removed ghost task(s) from database.");
            }else{
              System.out.println("No ghost tasks exist in database.");
            }
          }
        }finally{
          con.rollback();
        }
      }finally{
        final long endTime = System.currentTimeMillis();
        final double durationMinutes = (endTime-startTime)/60000.0;
        System.out.println("Execution lasted "+new DecimalFormat("#.##").format(durationMinutes)+" minutes.");
      }
      System.out.println("All operations successful.");
      return true;
    }catch(Throwable t){
      t.printStackTrace();
      return false;
    }
  }
}