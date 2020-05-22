//+------------------------------------------------------------------+
//|                                               DatabaseFrames.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property tester_no_cache

#define  STATS_FRAME  1
//+------------------------------------------------------------------+
//| Class for saving optimization results to the database            |
//+------------------------------------------------------------------+
class CDatabaseFrames
  {
public:
                     CDatabaseFrames(void) {};
                    ~CDatabaseFrames(void) {};
   //--- functions for working in the tester
   int               OnTesterInit(void);
   void              OnTesterDeinit(void);
   void              OnTester(const double OnTesterValue);
  };
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
int               CDatabaseFrames::OnTesterInit(void)
  {
//--- remember optimization start time
   datetime optimization_start=TimeLocal();
   string start_message=StringFormat("%s: optimization launched at %s",
                                     __FUNCTION__, TimeToString(TimeLocal(), TIME_MINUTES|TIME_SECONDS));
//--- show messages on the chart and the terminal journal
   Print(start_message);
   Comment(start_message);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| TesterDeinit function - read data from frames                    |
//+------------------------------------------------------------------+
void               CDatabaseFrames::OnTesterDeinit(void)
  {
//--- take the EA name and optimization end time
   // string filename="test.sqlite";
   string filename=MQLInfoString(MQL_PROGRAM_NAME)+" "+TimeToString(TimeCurrent())+".sqlite";
   StringReplace(filename, ":", "."); // ":" character is not allowed in file names
   StringReplace(filename, " ", "_");
//--- open/create the database in the common terminal folder
   int db=DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE );
   if(db==INVALID_HANDLE)
     {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return;
     }
   else
      Print("DB: ", filename, " opened successful");
//--- create the PASSES table

   if(DatabaseTableExists(db, "BUFFER"))
     {
      //--- delete the table
      if(!DatabaseExecute(db, "DROP TABLE BUFFER"))
        {
         Print("Failed to drop table BUFFER with code ", GetLastError());
         DatabaseClose(db);
         return;
        }
     }
   if(!DatabaseExecute(db, "CREATE TABLE BUFFER("
                       "PASS               INT PRIMARY KEY NOT NULL,"
                       "SYMBOL             TEXT,"
                       "FUNC               INT,"
                       "IDX                INT,"
                       "VALUE              REAL );"))  // NUMBERIC
     {
      Print("DB: ", filename, " create table failed with code ", GetLastError());
      DatabaseClose(db);
      return;
     }
//--- variables for reading frames
   string        symbol;
   ulong         pass;
   long          func;
   double        idx;
   double        values[];
//--- move the frame pointer to the beginning
   FrameFirst();
   // FrameFilter("", STATS_FRAME); // select frames with trading statistics for further work
//--- variables to get statistics from the frame
//--- block the database for the period of bulk transactions
   DatabaseTransactionBegin(db);

   string request="INSERT INTO BUFFER (PASS,SYMBOL,FUNC,IDX,VALUE)"
                               "VALUES (0, \"EURUSD\", 0, 0, 12.3456)";
   if(!DatabaseExecute(db, request))
   {
      PrintFormat("Failed to insert pass %d with code %d", pass, GetLastError());
   }

//--- go through frames and read data from them
   bool failed=false;
   while(FrameNext(pass, symbol, func, idx, values))
     {
      Print("Got pass #", pass);   // Uncomment for debugging only
      /*  Uncomment for debugging only
      PrintFormat("VALUES (%d,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%G,%.2f,%.2f,%2.f,%.2f,%.2f,%.2f,%.2f)",
                  pass, trades, win_trades_percent, profit, gross_profit, gross_loss, sharpe_ratio,
                  profit_factor, recovery_factor, expected_payoff, ontester_value, balance,
                  balance_plus_profitfactor, balance_plus_expectedpayoff, balance_plus_dd, balance_plus_recoveryfactor,
                  balance_plus_sharpe);
      */

        string request=StringFormat("INSERT INTO BUFFER (PASS,SYMBOL,FUNC,IDX,VALUE)"
                                    "VALUES (%d, \"%s\", %d, %d, %.8f)",
                                    pass, symbol, func, (int) idx, values[0]);
        if(!DatabaseExecute(db, request))
        {
           PrintFormat("Failed to insert pass %d with code %d", pass, GetLastError());
        }

      //--- write data to the table
        for(int i=0;i<ArraySize(values);i++) {
            string request=StringFormat("INSERT INTO BUFFER (PASS,SYMBOL,FUNC,IDX,VALUE)"
                                       "VALUES (%d, \"%s\", %d, %d, %.8f)",
                                       pass, symbol, func, (int) idx, values[i]);

            Print(request);

            //--- execute a query to add a pass to the PASSES table
            if(!DatabaseExecute(db, request))
            {
               PrintFormat("Failed to insert pass %d [%d] with code %d", pass, i, GetLastError());
               failed=true;
               break;
            }
        }
     }
//--- if an error occurred during a transaction, inform of that and complete the work
   if(failed)
     {
      Print("Transaction failed, error code=", GetLastError());
      DatabaseTransactionRollback(db);
      DatabaseClose(db);
      return;
     }
   else
     {
      DatabaseTransactionCommit(db);
      Print("Transaction done successfully");
     }
//--- close the database
   if(db!=INVALID_HANDLE)
     {
      PrintFormat("Close database with handle=%d", db);
      PrintFormat("Database stored in file '%s'", filename);
      DatabaseClose(db);

     }
//---
  }
//+------------------------------------------------------------------+
//| Tester function - sends trading statistics in a frame            |
//+------------------------------------------------------------------+
void               CDatabaseFrames::OnTester(const double OnTesterValue)
  {
//--- stats[] array to send data to a frame
   double stats[16];
//--- allocate separate variables for trade statistics to achieve more clarity
   int    trades=(int)TesterStatistics(STAT_TRADES);
   double win_trades_percent=0;
   if(trades>0)
      win_trades_percent=TesterStatistics(STAT_PROFIT_TRADES)*100./trades;
//--- fill in the array with test results
   stats[0]=trades;                                       // number of trades
   stats[1]=win_trades_percent;                           // percentage of profitable trades
   stats[2]=TesterStatistics(STAT_PROFIT);                // net profit
   stats[3]=TesterStatistics(STAT_GROSS_PROFIT);          // gross profit
   stats[4]=TesterStatistics(STAT_GROSS_LOSS);            // gross loss
   stats[5]=TesterStatistics(STAT_SHARPE_RATIO);          // Sharpe Ratio
   stats[6]=TesterStatistics(STAT_PROFIT_FACTOR);         // profit factor
   stats[7]=TesterStatistics(STAT_RECOVERY_FACTOR);       // recovery factor
   stats[8]=TesterStatistics(STAT_EXPECTED_PAYOFF);       // trade mathematical expectation
   stats[9]=OnTesterValue;                                // custom optimization criterion
//--- calculate built-in standard optimization criteria
   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double balance_plus_profitfactor=0;
   if(TesterStatistics(STAT_GROSS_LOSS)!=0)
      balance_plus_profitfactor=balance*TesterStatistics(STAT_PROFIT_FACTOR);
   double balance_plus_expectedpayoff=balance*TesterStatistics(STAT_EXPECTED_PAYOFF);
   double equity_dd=TesterStatistics(STAT_EQUITYDD_PERCENT);
   double balance_plus_dd=0;
   if(equity_dd!=0)
      balance_plus_dd=balance/equity_dd;
   double balance_plus_recoveryfactor=balance*TesterStatistics(STAT_RECOVERY_FACTOR);
   double balance_plus_sharpe=balance*TesterStatistics(STAT_SHARPE_RATIO);
//--- add the values of built-in optimization criteria
   stats[10]=balance;                                     // Balance
   stats[11]=balance_plus_profitfactor;                   // Balance+ProfitFactor
   stats[12]=balance_plus_expectedpayoff;                 // Balance+ExpectedPayoff
   stats[13]=balance_plus_dd;                             // Balance+EquityDrawdown
   stats[14]=balance_plus_recoveryfactor;                 // Balance+RecoveryFactor
   stats[15]=balance_plus_sharpe;                         // Balance+Sharpe
//--- create a data frame and send it to the terminal
   if(!FrameAdd(MQLInfoString(MQL_PROGRAM_NAME)+"_stats", STATS_FRAME, trades, stats))
      Print("Frame add error: ", GetLastError());
   else
      Print("Frame added, Ok");
  }
//+------------------------------------------------------------------+
// void               CDatabaseFrames::OnTesterDeinit(void)
//   {
// //--- take the EA name and optimization end time
//    string filename=MQLInfoString(MQL_PROGRAM_NAME)+" "+TimeToString(TimeCurrent())+".sqlite";
//    StringReplace(filename, ":", "."); // ":" character is not allowed in file names
// //--- open/create the database in the common terminal folder
//    int db=DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
//    if(db==INVALID_HANDLE)
//      {
//       Print("DB: ", filename, " open failed with code ", GetLastError());
//       return;
//      }
//    else
//       Print("DB: ", filename, " opened successful");
// //--- create the PASSES table
//    if(!DatabaseExecute(db, "CREATE TABLE PASSES("
//                        "PASS               INT PRIMARY KEY NOT NULL,"
//                        "TRADES             INT,"
//                        "WIN_TRADES         INT,"
//                        "PROFIT             REAL,"
//                        "GROSS_PROFIT       REAL,"
//                        "GROSS_LOSS         REAL,"
//                        "SHARPE_RATIO       REAL,"
//                        "PROFIT_FACTOR      REAL,"
//                        "RECOVERY_FACTOR    REAL,"
//                        "EXPECTED_PAYOFF    REAL,"
//                        "ON_TESTER          REAL,"
//                        "BL_BALANCE         REAL,"
//                        "BL_PROFITFACTOR    REAL,"
//                        "BL_EXPECTEDPAYOFF  REAL,"
//                        "BL_DD              REAL,"
//                        "BL_RECOVERYFACTOR  REAL,"
//                        "BL_SHARPE          REAL );"))
//      {
//       Print("DB: ", filename, " create table failed with code ", GetLastError());
//       DatabaseClose(db);
//       return;
//      }
// //--- variables for reading frames
//    string        name;
//    ulong         pass;
//    long          id;
//    double        value;
//    double        stats[];
// //--- move the frame pointer to the beginning
//    FrameFirst();
//    FrameFilter("", STATS_FRAME); // select frames with trading statistics for further work
// //--- variables to get statistics from the frame
//    int trades;
//    double win_trades_percent;
//    double profit, gross_profit, gross_loss;
//    double sharpe_ratio, profit_factor, recovery_factor, expected_payoff;
//    double ontester_value;                              // custom optimization criterion
//    double balance;                                     // Balance
//    double balance_plus_profitfactor;                   // Balance+ProfitFactor
//    double balance_plus_expectedpayoff;                 // Balance+ExpectedPayoff
//    double balance_plus_dd;                             // Balance+EquityDrawdown
//    double balance_plus_recoveryfactor;                 // Balance+RecoveryFactor
//    double balance_plus_sharpe;                         // Balance+Sharpe
// //--- block the database for the period of bulk transactions
//    DatabaseTransactionBegin(db);
// //--- go through frames and read data from them
//    bool failed=false;
//    while(FrameNext(pass, name, id, value, stats))
//      {
//       //Print("Got pass #", pass);   // Uncomment for debugging only
//       trades=(int)stats[0];
//       win_trades_percent=stats[1];
//       profit=stats[2];
//       gross_profit=stats[3];
//       gross_loss=stats[4];
//       sharpe_ratio=stats[5];
//       profit_factor=stats[6];
//       recovery_factor=stats[7];
//       expected_payoff=stats[8];
//       ontester_value=stats[9];
//       balance=stats[10];
//       balance_plus_profitfactor=stats[11];
//       balance_plus_expectedpayoff=stats[12];
//       balance_plus_dd=stats[13];
//       balance_plus_recoveryfactor=stats[14];
//       balance_plus_sharpe=stats[15];
//       /*  Uncomment for debugging only
//       PrintFormat("VALUES (%d,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%G,%.2f,%.2f,%2.f,%.2f,%.2f,%.2f,%.2f)",
//                   pass, trades, win_trades_percent, profit, gross_profit, gross_loss, sharpe_ratio,
//                   profit_factor, recovery_factor, expected_payoff, ontester_value, balance,
//                   balance_plus_profitfactor, balance_plus_expectedpayoff, balance_plus_dd, balance_plus_recoveryfactor,
//                   balance_plus_sharpe);
//       */
//       //--- write data to the table
//       string request=StringFormat("INSERT INTO PASSES (PASS,TRADES,WIN_TRADES, PROFIT,GROSS_PROFIT,GROSS_LOSS,"
//                                   "SHARPE_RATIO,PROFIT_FACTOR,RECOVERY_FACTOR,EXPECTED_PAYOFF,ON_TESTER,"
//                                   "BL_BALANCE,BL_PROFITFACTOR,BL_EXPECTEDPAYOFF,BL_DD,BL_RECOVERYFACTOR,BL_SHARPE) "
//                                   "VALUES (%d, %d, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %G, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f)",
//                                   pass, trades, win_trades_percent, profit, gross_profit, gross_loss, sharpe_ratio,
//                                   profit_factor, recovery_factor, expected_payoff, ontester_value, balance,
//                                   balance_plus_profitfactor, balance_plus_expectedpayoff, balance_plus_dd, balance_plus_recoveryfactor,
//                                   balance_plus_sharpe);

//       //--- execute a query to add a pass to the PASSES table
//       if(!DatabaseExecute(db, request))
//         {
//          PrintFormat("Failed to insert pass %d with code %d", pass, GetLastError());
//          failed=true;
//          break;
//         }
//      }
// //--- if an error occurred during a transaction, inform of that and complete the work
//    if(failed)
//      {
//       Print("Transaction failed, error code=", GetLastError());
//       DatabaseTransactionRollback(db);
//       DatabaseClose(db);
//       return;
//      }
//    else
//      {
//       DatabaseTransactionCommit(db);
//       Print("Transaction done successfully");
//      }
// //--- close the database
//    if(db!=INVALID_HANDLE)
//      {
//       PrintFormat("Close database with handle=%d", db);
//       PrintFormat("Database stored in file '%s'", filename);
//       DatabaseClose(db);

//      }
// //---
//   }
// //+------------------------------------------------------------------+
// //| Tester function - sends trading statistics in a frame            |
// //+------------------------------------------------------------------+
// void               CDatabaseFrames::OnTester(const double OnTesterValue)
//   {
// //--- stats[] array to send data to a frame
//    double stats[16];
// //--- allocate separate variables for trade statistics to achieve more clarity
//    int    trades=(int)TesterStatistics(STAT_TRADES);
//    double win_trades_percent=0;
//    if(trades>0)
//       win_trades_percent=TesterStatistics(STAT_PROFIT_TRADES)*100./trades;
// //--- fill in the array with test results
//    stats[0]=trades;                                       // number of trades
//    stats[1]=win_trades_percent;                           // percentage of profitable trades
//    stats[2]=TesterStatistics(STAT_PROFIT);                // net profit
//    stats[3]=TesterStatistics(STAT_GROSS_PROFIT);          // gross profit
//    stats[4]=TesterStatistics(STAT_GROSS_LOSS);            // gross loss
//    stats[5]=TesterStatistics(STAT_SHARPE_RATIO);          // Sharpe Ratio
//    stats[6]=TesterStatistics(STAT_PROFIT_FACTOR);         // profit factor
//    stats[7]=TesterStatistics(STAT_RECOVERY_FACTOR);       // recovery factor
//    stats[8]=TesterStatistics(STAT_EXPECTED_PAYOFF);       // trade mathematical expectation
//    stats[9]=OnTesterValue;                                // custom optimization criterion
// //--- calculate built-in standard optimization criteria
//    double balance=AccountInfoDouble(ACCOUNT_BALANCE);
//    double balance_plus_profitfactor=0;
//    if(TesterStatistics(STAT_GROSS_LOSS)!=0)
//       balance_plus_profitfactor=balance*TesterStatistics(STAT_PROFIT_FACTOR);
//    double balance_plus_expectedpayoff=balance*TesterStatistics(STAT_EXPECTED_PAYOFF);
//    double equity_dd=TesterStatistics(STAT_EQUITYDD_PERCENT);
//    double balance_plus_dd=0;
//    if(equity_dd!=0)
//       balance_plus_dd=balance/equity_dd;
//    double balance_plus_recoveryfactor=balance*TesterStatistics(STAT_RECOVERY_FACTOR);
//    double balance_plus_sharpe=balance*TesterStatistics(STAT_SHARPE_RATIO);
// //--- add the values of built-in optimization criteria
//    stats[10]=balance;                                     // Balance
//    stats[11]=balance_plus_profitfactor;                   // Balance+ProfitFactor
//    stats[12]=balance_plus_expectedpayoff;                 // Balance+ExpectedPayoff
//    stats[13]=balance_plus_dd;                             // Balance+EquityDrawdown
//    stats[14]=balance_plus_recoveryfactor;                 // Balance+RecoveryFactor
//    stats[15]=balance_plus_sharpe;                         // Balance+Sharpe
// //--- create a data frame and send it to the terminal
//    if(!FrameAdd(MQLInfoString(MQL_PROGRAM_NAME)+"_stats", STATS_FRAME, trades, stats))
//       Print("Frame add error: ", GetLastError());
//    else
//       Print("Frame added, Ok");
//   }
// //+------------------------------------------------------------------+
