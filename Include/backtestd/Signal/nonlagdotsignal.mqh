//+------------------------------------------------------------------+
//|                                              NonLagDotSignal.mqh |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
//+------------------------------------------------------------------+
//| Included files                                                   |
//+------------------------------------------------------------------+
#property tester_indicator "Indi\NonLagDot.ex5"
#include <..\Experts\BacktestExpert\Signal\CustomSignal.mqh>
#define PRODUCE_nonlagdotsignal

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
//| Title=The signals based on NonLagDot indicator                       |
//| Type=SignalAdvanced                                                  |
//| Name=NonLagDot                                                       |
//| Class=CNonLagDotSignal                                               |
//| Page=                                                                |
//| Parameter=BuyPosOpen,bool,true,Permission to buy                     |
//| Parameter=SellPosOpen,bool,true,Permission to sell                   |
//| Parameter=BuyPosClose,bool,true,Permission to exit a long position   |
//| Parameter=SellPosClose,bool,true,Permission to exit a short position |
//| Parameter=Ind_Timeframe,ENUM_TIMEFRAMES,PERIOD_H4,Timeframe          |
//| Parameter=Price,ENUM_APPLIED_PRICE,PRICE_CLOSE,applied price         |
//| Parameter=Type,ENUM_MA_METHOD,MODE_SMA,smoothing method              |
//| Parameter=Length,uint,10,indicator calculation period                |
//| Parameter=Filter,uint,0,filter                                       |
//| Parameter=Swing,double,0,deviation                                   |
//| Parameter=SignalBar,uint,1,Bar index for entry signal                |
//+----------------------------------------------------------------------+
//--- wizard description end
//+----------------------------------------------------------------------+
//| CNonLagDotSignal class.                                              |
//| Purpose: Class of generator of trade signals based on                |
//| NonLagDot indicator http://www.mql5.com/ru/code/694/.                |
//| Is derived from the CExpertSignal class.                             |
//+----------------------------------------------------------------------+
class CNonLagDotSignal : public CCustomSignal
  {
protected:
   CiCustom          m_indicator;        // the object for access to NonLagDot values

   //--- adjusted parameters
   bool              m_BuyPosOpen;       // permission to buy
   bool              m_SellPosOpen;      // permission to sell
   bool              m_BuyPosClose;      // permission to exit a long position
   bool              m_SellPosClose;     // permission to exit a short position
   ENUM_TIMEFRAMES   m_Ind_Timeframe;    // NonLagDot indicator timeframe
   ENUM_APPLIED_PRICE m_Price;           // Applied price
   ENUM_MA_METHOD    m_Type;             // Smoothing method
   uint              m_Length;           // Indicator calculation period
   uint              m_Filter;           // Filter
   double            m_Swing;            // Deviation   
   uint              m_SignalBar;        // bar index for getting entry signal

public:
                     CNonLagDotSignal();

   //--- methods of setting adjustable parameters
   void              BuyPosOpen(bool value)                  { m_BuyPosOpen=value;       }
   void              SellPosOpen(bool value)                 { m_SellPosOpen=value;      }
   void              BuyPosClose(bool value)                 { m_BuyPosClose=value;      }
   void              SellPosClose(bool value)                { m_SellPosClose=value;     }
   void              Ind_Timeframe(ENUM_TIMEFRAMES value)    { m_Ind_Timeframe=value;    }
   void              Price(ENUM_APPLIED_PRICE value)         { m_Price=value;            }
   void              Type(ENUM_MA_METHOD value)              { m_Type=value;             }
   void              Length(uint value)                      { m_Length=value;           }
   void              Filter(uint value)                      { m_Filter=value;           }
   void              Swing(double value)                     { m_Swing=value;            }
   void              SignalBar(uint value)                   { m_SignalBar=value;        }

   //--- adjustable parameters validation method
   virtual bool      ValidationSettings();
   //--- adjustable parameters validation method
   virtual bool      InitIndicators(CIndicators *indicators); // indicators initialization
   //--- market entry signals generation method
   virtual int       LongCondition();
   virtual int       ShortCondition();

   bool              InitNonLagDot(CIndicators *indicators);  // NonLagDot indicator initializing method
  };
//+------------------------------------------------------------------+
//| CNonLagDotSignal constructur.                                    |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CNonLagDotSignal::CNonLagDotSignal()
  {
//--- setting default values
   m_BuyPosOpen=true;
   m_SellPosOpen=true;
   m_BuyPosClose=true;
   m_SellPosClose=true;

//--- indicator input parameters
   m_Ind_Timeframe=PERIOD_H4;
   m_Price=PRICE_CLOSE;
   m_Type=MODE_SMA;
   m_Length=10;
   m_Filter=0;
   m_Swing=0;
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
bool CNonLagDotSignal::ValidationSettings()
  {
//--- checking parameters
   if(m_Length<=0)
     {
      printf(__FUNCTION__+": indicator calculation period must be above zero");
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
bool CNonLagDotSignal::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer
   if(indicators==NULL) return(false);

//--- indicator initialization
   if(!InitNonLagDot(indicators)) return(false);

//--- successful completion
   return(true);
  }
//+------------------------------------------------------------------+
//| NonLagDot indicator initialization.                              |
//| INPUT:  indicators - pointer to an object-collection             |
//|                      of indicators and time series.              |
//| OUTPUT: true - in case of successful, otherwise - false.         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CNonLagDotSignal::InitNonLagDot(CIndicators *indicators)
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
   MqlParam parameters[6];
   
   parameters[0].type=TYPE_STRING;
   parameters[0].string_value="Indi\NonLagDot.ex5";
   
   parameters[1].type=TYPE_UINT;
   parameters[1].integer_value=m_Price;
   
   parameters[2].type=TYPE_UINT;
   parameters[2].integer_value=m_Type;
   
   parameters[3].type=TYPE_UINT;
   parameters[3].integer_value=m_Length;
   
   parameters[4].type=TYPE_UINT;
   parameters[4].integer_value=m_Filter;
   
   parameters[5].type=TYPE_DOUBLE;
   parameters[5].double_value=m_Swing;

//--- object initialization   
   if(!m_indicator.Create(m_symbol.Name(),m_Ind_Timeframe,IND_CUSTOM,6,parameters))
     {
      printf(__FUNCTION__+": object initialization error");
      return(false);
     }
     
//--- number of buffers
   if(!m_indicator.NumBuffers(2)) return(false);
   
//--- NonLagDot indicator initialized successfully
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking conditions for opening                                  |
//| a long position and closing a short one                          |
//| INPUT:  no                                                       |
//| OUTPUT: Vote weight from 0 to 100                                |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CNonLagDotSignal::LongCondition()
  {
//--- buy signal is determined by buffer 1 of the NonLagDot indicator
   double Signal0=m_indicator.GetData(1,m_SignalBar);
   double Signal1=m_indicator.GetData(1,m_SignalBar+1);

//--- getting a trading signal 
   if(Signal0==2)
     {
      if(Signal1==1)
        {

         if(m_BuyPosOpen)
           {
            if(m_SellPosClose) return(REVERSE_SHORT);
            else return(OPEN_LONG);
           }

         if(m_SellPosClose) return(CLOSE_SHORT);
        }
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
int CNonLagDotSignal::ShortCondition()
  {
//--- sell signal is determined by buffer 1 of the NonLagDot indicator
   double Signal0=m_indicator.GetData(1,m_SignalBar);
   double Signal1=m_indicator.GetData(1,m_SignalBar+1);

//--- getting a trading signal 
   if(Signal0==1)
     {
      if(Signal1==2)
        {

         if(m_SellPosOpen)
           {
            if(m_BuyPosClose) return(REVERSE_LONG);
            else return(OPEN_SHORT);
           }

         if(m_BuyPosClose) return(CLOSE_LONG);
        }
     }
//--- no trading signal   
   return(NO_SIGNAL);
  }
//+------------------------------------------------------------------+
