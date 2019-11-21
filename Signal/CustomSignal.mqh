//+------------------------------------------------------------------+
//|                                                    SignalTCT.mqh |
//|                                     Copyright 2019, Stefan Lendl |
//|                                                                  |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include "..\Expert\Assert.mqh"

// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator 'Adaptive Moving Average'             |
//| Type=SignalAdvanced                                              |
//| Name=Adaptive Moving Average                                     |
//| ShortName=AMA                                                    |
//| Class=CCustomSignal                                                 |
//| Page=signal_ama                                                  |
//| Parameter=PeriodMA,int,10,Period of averaging                    |
//| Parameter=PeriodFast,int,2,Period of fast EMA                    |
//| Parameter=PeriodSlow,int,30,Period of slow EMA                   |
//| Parameter=Shift,int,0,Time shift                                 |
//| Parameter=Applied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Prices series   |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CCustomSignal.                                                |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Adaptive Moving Average' indicator.                |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CCustomSignal : public CExpertSignal
  {
protected:
   //--- adjusted parameters
   MqlParam           m_params[];
   int                m_params_size;
   CiCustom           m_indicator;             // object-indicator for subclassed signals
   ENUM_INDICATOR     m_indicator_type;


   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0 "price is on the necessary side from the indicator"
   int               m_pattern_1;      // model 1 "price crossed the indicator with opposite direction"
   int               m_pattern_2;      // model 2 "price crossed the indicator with the same direction"
   int               m_pattern_3;      // model 3 "piercing"

   //--- adjusted parameters
   bool              m_BuyPosOpen;       // permission to buy
   bool              m_SellPosOpen;      // permission to sell
   bool              m_BuyPosClose;      // permission to exit a long position
   bool              m_SellPosClose;     // permission to exit a short position
   ENUM_TIMEFRAMES   m_Ind_Timeframe;    // Indicator timeframe

   ENUM_APPLIED_PRICE m_IPC;             // applied price
   uint               m_Filter_Points;   // Filter in Points
   uint               m_Shift;           // bar index for entry signal

public:
                     CCustomSignal(void);
                    ~CCustomSignal(void);
   //--- methods of setting adjustable parameters
   void              Params(MqlParam &param[], int size);
   virtual void      ParamsFromInput(double &Signal_double[]);

   //--- methods of adjusting "weights" of market models
   void              Pattern_0(int value)                { m_pattern_0=value;          }
   void              Pattern_1(int value)                { m_pattern_1=value;          }
   void              Pattern_2(int value)                { m_pattern_2=value;          }
   void              Pattern_3(int value)                { m_pattern_3=value;          }

   //--- methods of setting adjustable parameters
   void               BuyPosOpen(bool value)                  { m_BuyPosOpen=value;       }
   void               SellPosOpen(bool value)                 { m_SellPosOpen=value;      }
   void               BuyPosClose(bool value)                 { m_BuyPosClose=value;      }
   void               SellPosClose(bool value)                { m_SellPosClose=value;     }
   void               Ind_Timeframe(ENUM_TIMEFRAMES value)    { m_Ind_Timeframe=value;    }
   void               IPC(ENUM_APPLIED_PRICE value)           { m_IPC=value;              }
   void               FilterPoints(uint value)                { m_Filter_Points=value;    }
   void               Shift(uint value)                       { m_Shift=value;            }
   void               IndicatorType(ENUM_INDICATOR value)               { m_indicator_type=value;   }

   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void)                                      { return(0);     }
   virtual int       ShortCondition(void)                                     { return(0);     }
   virtual double    GetData(const int buffer_num);

   virtual bool      LongSide(void)   { return Side() > 0 ? true : false; }
   virtual bool      ShortSide(void)  { return Side() < 0 ? true : false; }
   virtual bool      LongSignal(void) { return Direction() > 0 ? true : false; }
   virtual bool      ShortSignal(void) { return Direction() < 0 ? true : false; }

   // if Side() is not defined, use the direction and scale it up to 100
   virtual int       Side(void) { return(Direction()>0) ? 100 : -100; }

protected:
   //--- method of initialization of the indicator
   bool              InitCustomIndicator(CIndicators *indicators);
   virtual bool      InitIndicatorBuffers()                                  { return true; }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CCustomSignal::CCustomSignal(void) : m_indicator_type(IND_CUSTOM)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CCustomSignal::~CCustomSignal(void)
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCustomSignal::Params(MqlParam &param[], int size)
  {
   m_params_size = size;
   ArrayResize(m_params, size);
   for(int i=0; i<size; i++)
     {
      m_params[i] = param[i];
     }
  }

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CCustomSignal::ValidationSettings(void)
  {
//--- call of the method of the parent class
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks
   if(m_params_size < 1)
     {
      printf(__FUNCTION__+": params size must be >1");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CCustomSignal::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize AMA indicator
   if(!InitCustomIndicator(indicators))
      return(false);
   if(!InitIndicatorBuffers())
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create MA indicators.                                            |
//+------------------------------------------------------------------+
bool CCustomSignal::InitCustomIndicator(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add object to collection
   if(!indicators.Add(GetPointer(m_indicator)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_indicator.Create(m_symbol.Name(), m_period, m_indicator_type, m_params_size, m_params))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CCustomSignal::GetData(const int buffer_num)
  {
   assert(GetPointer(m_indicator) != NULL, "m_indicator not declared");
// TODO consider m_Shift...
   return m_indicator.GetData(buffer_num, m_every_tick ? 0 : 1);
  }
//+------------------------------------------------------------------+
