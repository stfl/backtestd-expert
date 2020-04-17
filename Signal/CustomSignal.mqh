//+------------------------------------------------------------------+
//|                                                 CustomSignal.mqh |
//|                                     Copyright 2019, Stefan Lendl |
//|                                                                  |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include "..\Expert\Assert.mqh"

// macro used to produce the signals in SignalFactory
// if the indicator_name is found here we call it's custom implementation
#define PRODUCE(STR, CLASS)                    \
    if(StringCompare(name, STR, false)==0) {  \
      CLASS *signal=new CLASS;                 \
      assert_signal;                           \
      if (!signal.ValidationInputs(inputs))  \
         return NULL;                          \
      signal.ParamsFromInput(inputs);   \
      signal.Shift(shift);              \
      signal.Ind_Timeframe(time_frame);  \
      return signal;                           \
     }

class CCustomSignal : public CExpertSignal
  {
protected:
   //--- adjusted parameters
   MqlParam           m_params[];
   uint               m_params_size;
   CiCustom           m_indicator;             // object-indicator for subclassed signals
   ENUM_INDICATOR     m_indicator_type;
   ENUM_TIMEFRAMES   m_Ind_Timeframe;    // Indicator timeframe

   ENUM_APPLIED_PRICE m_IPC;             // applied price
   uint               m_Filter_Points;   // Filter in Points
   uint               m_Idx;             // bar index to consider
   uint               m_Shift;           // shifting bar index
   string             m_indicator_file;
   // string             m_indicator_name;

   uint m_buffers[];
   double m_config[];

public:
                     CCustomSignal(void);
                    ~CCustomSignal(void);
   //--- methods of setting adjustable parameters
        void         Params(MqlParam &param[], int size); // { ArrayCopy(m_params, param); m_params_size = ArraySize(m_params); }
   virtual void      ParamsFromInput(double &inputs[]);
   virtual void      Buffers(uint &buffers[]) { ArrayCopy(m_buffers, buffers); }
   virtual void      Config(double &config[]) { ArrayCopy(m_config, config); }  // assigning Levels and Colors to the Indicator according to the indi class

   void               Ind_Timeframe(ENUM_TIMEFRAMES value)    { m_Ind_Timeframe=value;    }  // TODO rename TimeFrame
   void               IPC(ENUM_APPLIED_PRICE value)           { m_IPC=value;              }  // TODO remove
   void               FilterPoints(uint value)                { m_Filter_Points=value;    }  // TODO needed?
   void               Shift(uint value)                       { m_Shift=value; m_Idx+=m_Shift; }
   void               IndicatorType(ENUM_INDICATOR value)      { m_indicator_type=value;   }
   void               IndicatorFile(string filename);
   // void               IndicatorName(string name)               { m_indicator_name=name;   }

   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   virtual bool      ValidationInputs(double &inputs[]) { return true; }
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed

   virtual int       LongCondition(void)                                      { return(0);     } // TODO delete
   virtual int       ShortCondition(void)                                     { return(0);     } // TODO delete
   virtual double    GetData(const int buffer_num, uint shift=0);

   virtual bool      LongSide(void)   { return Side() > 0 ? true : false; }
   virtual bool      ShortSide(void)  { return Side() < 0 ? true : false; }
   virtual bool      LongSignal(void) { return Direction() > 0 ? true : false; }  // TODO replace with CheckOpenLong
   virtual bool      ShortSignal(void) { return Direction() < 0 ? true : false; } // TODO replace with CheckOpenShort
   virtual bool      LongExit(void) { return ShortSignal(); } // TODO CheckCloseLong
   virtual bool      ShortExit(void) { return LongSignal(); } // TODO CheckCloseShort

   // if Side() is not defined, use the direction and scale it up to 100
   virtual int       Side(void) { return(Direction()>0) ? 100 : -100; }     // TODO implement Direction instead of Side in the subclasses

protected:
   //--- method of initialization of the indicator
   bool              InitCustomIndicator(CIndicators *indicators);         // TODO replace with CreateIndicator
   virtual bool      InitIndicatorBuffers()                                  { return true; }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CCustomSignal::CCustomSignal(void) : m_indicator_type(IND_CUSTOM)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
   m_Idx = StartIndex();
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
   m_params_size = size; // TODO this can be replaced by ArraySize(param)
   ArrayResize(m_params, size);
   for(int i=0; i<size; i++)
     {
      m_params[i] = param[i];
     }
  }

// TODO if we need to consider &Signal_string[] this can be checked in the for loop
// if inputs[i] != "" > set in MqlParam array
void CCustomSignal::ParamsFromInput(double &inputs[])
{
   uint size = ArraySize(inputs);
   m_params_size = size+1;
   ArrayResize(m_params, m_params_size);

   m_params[0].type=TYPE_STRING;
   m_params[0].string_value=m_indicator_file;

   for(int i=0; i<size; i++) {
      m_params[i+1].type=TYPE_DOUBLE;
      m_params[i+1].double_value=inputs[i];
   }
}

void CCustomSignal::IndicatorFile(string filename)               {
   m_indicator_file=filename;
   if (m_params_size > 0) { // the Params where already generated. so we overwrite it in the params as well
      m_params[0].string_value=m_indicator_file;
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
   if(!InitIndicatorBuffers()) // TODO this call can be moves to an overloading of InitIndicators in the subclass
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicator.                                            |
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
double CCustomSignal::GetData(const int buffer_num, uint shift)
  {
   assert(GetPointer(m_indicator) != NULL, "m_indicator not declared");
   return m_indicator.GetData(buffer_num, m_Idx + shift);
  }
//+------------------------------------------------------------------+
