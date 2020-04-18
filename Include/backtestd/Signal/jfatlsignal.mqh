//+------------------------------------------------------------------+
//|                                                  JFatlSignal.mqh |
//|                             Copyright © 2012,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
//+------------------------------------------------------------------+
//| Included files                                                   |
//+------------------------------------------------------------------+
#property tester_indicator "Indi\ColorJFatl.ex5"
#include <..\Experts\BacktestExpert\Signal\CustomSignal.mqh>
#define PRODUCE_jfatlsignal

//--- wizard description start
//+------------------------------------------------------------------+ 
//|  Declaration of constants                                        |
//+------------------------------------------------------------------+ 
#define OPEN_LONG     80  // The constant for returning the buy command to the Expert Advisor
#define OPEN_SHORT    80  // The constant for returning the sell command to the Expert Advisor
#define CLOSE_LONG    40  // The constant for returning the command to close a long position to the Expert Advisor
#define CLOSE_SHORT   40  // The constant for returning the command to close a short position to the Expert Advisor
#define REVERSE_LONG  100 // The constant for returning the command to reverse a long position to the Expert Advisor
#define REVERSE_SHORT 100 // The constant for returning the command to reverse a short position to the Expert Advisor
#define NO_SIGNAL      0  // The constant for returning the absence of a signal to the Expert Advisor
//+----------------------------------------------------------------------+
//| Description of the class                                             |
//| Title=The signals based on ColorJFatl                                |
//| Type=SignalAdvanced                                                  |
//| Name=JFatl                                                           |
//| Class=CJFatlSignal                                                   |
//| Page=                                                                |
//| Parameter=BuyPosOpen,bool,true,Permission to buy                     |
//| Parameter=SellPosOpen,bool,true,Permission to sell                   |
//| Parameter=BuyPosClose,bool,true,Permission to exit a long position   |
//| Parameter=SellPosClose,bool,true,Permission to exit a short position |
//| Parameter=Ind_Timeframe,ENUM_TIMEFRAMES,PERIOD_H4,Timeframe          |
//| Parameter=Length_,uint,5,JMA smoothing depth                         |
//| Parameter=Phase_,int,100,JMA smoothing parameter (-100...100)        |
//| Parameter=IPC,uint,0,Applied price (0...11)                          |           
//| Parameter=SignalBar,uint,1,Bar index for entry signal                |
//+----------------------------------------------------------------------+
//--- wizard description end
//+----------------------------------------------------------------------+
//| CJFatlSignal class.                                                  |
//| Purpose: Class of generator of trade signals based on                |
//| ColorJFatl indicator http://www.mql5.com/en/code/430                 |
//| Is derived from the CExpertSignal class.                             |
//+----------------------------------------------------------------------+
class CJFatlSignal : public CCustomSignal
  {
protected:
   CiCustom          m_indicator;        // the object for access to JFatl values

   //--- adjusted parameters
   bool              m_BuyPosOpen;       // permission to buy
   bool              m_SellPosOpen;      // permission to sell
   bool              m_BuyPosClose;      // permission to exit a long position
   bool              m_SellPosClose;     // permission to exit a short position
   ENUM_TIMEFRAMES   m_Ind_Timeframe;    // JFatl indicator timeframe
   uint              m_Length_;          // depth of JMA smoothing
   uint              m_Phase_;           // JMA smoothing parameter (-100...100)
   int               m_IPC;              // applied price (0...11)
   uint              m_SignalBar;        // Bar index for getting entry signal

public:
                     CJFatlSignal();

   //--- methods of setting adjustable parameters
   void              BuyPosOpen(bool value)                  { m_BuyPosOpen=value;       }
   void              SellPosOpen(bool value)                 { m_SellPosOpen=value;      }
   void              BuyPosClose(bool value)                 { m_BuyPosClose=value;      }
   void              SellPosClose(bool value)                { m_SellPosClose=value;     }
   void              Ind_Timeframe(ENUM_TIMEFRAMES value)    { m_Ind_Timeframe=value;    }
   void              Length_(uint value)                     { m_Length_=value;          }
   void              Phase_(int value)                       { m_Phase_=value;           }
   void              IPC(int value)                          { m_IPC=value;              }
   void              SignalBar(uint value)                   { m_SignalBar=value;        }

   //--- adjustable parameters validation method
   virtual bool      ValidationSettings();
   //--- adjustable parameters validation method
   virtual bool      InitIndicators(CIndicators *indicators); // indicators initialization
   //--- market entry signals generation methods
   virtual int       LongCondition();
   virtual int       ShortCondition();

   bool              InitJFatl(CIndicators *indicators);   // ColorJFatl indicator initializing method

protected:

  };
//+------------------------------------------------------------------+
//| CJFatlSignal constructor.                                        |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CJFatlSignal::CJFatlSignal()
  {
//--- setting default values
   m_BuyPosOpen=true;
   m_SellPosOpen=true;
   m_BuyPosClose=true;
   m_SellPosClose=true;

//--- indicator input parameters
   m_Ind_Timeframe=PERIOD_H4;
   m_Length_=5;
   m_Phase_=100;
   m_IPC=0;
//---  
   m_SignalBar=1;
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Checking adjustable parameters.                                  |
//| INPUT:  no.                                                      |
//| OUTPUT: true, if the settings are valid, false - if not.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CJFatlSignal::ValidationSettings()
  {
//--- checking parameters
   if(m_IPC>11)
     {
      printf(__FUNCTION__+": m_IPC indicator parameter cannot be more than 11");
      return(false);
     }

//--- successful completion
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialization of indicators and time series.                    |
//| INPUT:  indicators - pointer to an object-collection             |
//|                      of indicators and time series.              |
//| OUTPUT: true - in case of successful, otherwise - false.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CJFatlSignal::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer
   if(indicators==NULL) return(false);

//--- indicator initialization 
   if(!InitJFatl(indicators)) return(false);

//--- successful completion
   return(true);
  }
//+------------------------------------------------------------------+
//| ColorJFatl indicator initialization.                             |
//| INPUT:  indicators - pointer to an object-collection             |
//|                      of indicators and time series.              |
//| OUTPUT: true - in case of successful, otherwise - false.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CJFatlSignal::InitJFatl(CIndicators *indicators)
  {
//--- check of pointer
   if(indicators==NULL) return(false);

//--- adding an object to the collection
   if(!indicators.Add(GetPointer(m_indicator)))
     {
      printf(__FUNCTION__+": error of adding the object");
      return(false);
     }

//--- setting the indicator parameters
   MqlParam parameters[4];
   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="Indi\ColorJFatl.ex5";
   parameters[1].type=TYPE_UINT;
   parameters[1].integer_value=m_Length_;
   parameters[2].type=TYPE_INT;
   parameters[2].integer_value=m_Phase_;
   parameters[3].type=TYPE_UINT;
   parameters[3].integer_value=m_IPC;

//--- object initialization   
   if(!m_indicator.Create(m_symbol.Name(),m_Ind_Timeframe,IND_CUSTOM,4,parameters))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);
     }
     
//--- number of buffers
   if(!m_indicator.NumBuffers(2)) return(false);
   
//--- ColorJFatl indicator initialized successfully
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening                                  |
//| a long position and closing a short one                          |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CJFatlSignal::LongCondition()
  {
//--- buy signal is determined by buffer 1 of the ColorJFatl indicator
   double Signal0=m_indicator.GetData(1,m_SignalBar);
   double Signal1=m_indicator.GetData(1,m_SignalBar+1);

//--- getting a trading signal 
   if(Signal0==1)
     {
      if(Signal1==2 && m_BuyPosOpen)
        {
         if(m_SellPosClose) return(REVERSE_SHORT);
         else return(OPEN_LONG);
        }

      if(m_SellPosClose) return(CLOSE_SHORT);
     }
//--- no trading signal
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening                                  |
//| a short position and closing a long one                          |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CJFatlSignal::ShortCondition()
  {
//--- sell signal is determined by buffer 1 of the ColorJFatl indicator
   double Signal0=m_indicator.GetData(1,m_SignalBar);
   double Signal1=m_indicator.GetData(1,m_SignalBar+1);

//--- getting a trading signal 
   if(Signal0==2)
     {
      if(Signal1==1 && m_SellPosOpen)
        {
         if(m_BuyPosClose) return(REVERSE_LONG);
         else return(OPEN_SHORT);
        }

      if(m_BuyPosClose) return(CLOSE_LONG);
     }
//--- no trading signal   
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+
