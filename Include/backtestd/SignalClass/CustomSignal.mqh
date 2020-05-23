//+------------------------------------------------------------------+
//|                                                 CustomSignal.mqh |
//|                                     Copyright 2019, Stefan Lendl |
//|                                                                  |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <backtestd\Expert\Assert.mqh>

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

enum SIGNAL_STATE {
   SignalInit,
   SignalNoTrade,
   SignalLong,
   SignalLongReturn,
   SignalShort,
   SignalShortReturn,
};

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

   int m_sig_direction; // <0 short | 0 no signal | >0 long
   int m_exit_direction; // <0 exit long | 0 no exit signal | >0 exit short
   int m_side;

   SIGNAL_STATE m_state;

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

   virtual double    GetData(const int buffer_num, uint shift=0);

   // the default implementations return the stored signal and direction states which are calculated once per round with Update()
   // Signals may also choose to implement these Methods directly if calculations are easily perfomed stateless
   // where Update() is not required
   virtual int       Side(void) { return m_side; }
   virtual bool      LongSide(void)   { return Side() > 0 ? true : false; }
   virtual bool      ShortSide(void)  { return Side() < 0 ? true : false; }

   virtual int       SignalDirection(void) {return m_sig_direction; }
   virtual bool      LongSignal(void) { return SignalDirection() > 0 ? true : false; }
   virtual bool      ShortSignal(void) { return SignalDirection() < 0 ? true : false; }

   virtual int       ExitDirection(void) {return m_exit_direction; }
   virtual bool      LongExit(void) { return ExitDirection() <0 ? true : false; }
   virtual bool      ShortExit(void) { return ExitDirection() >0 ? true : false; }

   //--- methods for generating signals of modification of pending orders
   virtual bool      CheckTrailingOrderLong(COrderInfo *order,double &price)  { return(false); }
   virtual bool      CheckTrailingOrderShort(COrderInfo *order,double &price) { return(false); }
   //--- methods of checking if the market models are formed
   virtual double    Direction(void) { return m_direction; }

   // the stored direction states need to be updated every round (candle) only once!
   // getting the stored states later will be faster than calculating each time
   virtual bool Update();
   virtual bool UpdateSide(void);
   SIGNAL_STATE GetState() { return m_state; }

   bool WriteBuffersToFile(datetime date_start, string filename);
   bool GetIndiBuffers(datetime date_start, uint idx, double &indi_buf[]);
   bool AddBuffersToFrame(datetime date_start);
   bool AddSideChangeToFrame();

protected:
   //--- method of initialization of the indicator
   bool              InitCustomIndicator(CIndicators *indicators);         // TODO replace with CreateIndicator
   virtual bool      InitIndicatorBuffers()                                  { return true; }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CCustomSignal::CCustomSignal(void) : m_indicator_type(IND_CUSTOM),
                                     m_sig_direction(0),
                                     m_exit_direction(0),
                                     m_side(0),
                                     m_state(SignalInit)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
   m_Idx = StartIndex();
   ArrayResize(m_buffers, 5);
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CCustomSignal::~CCustomSignal(void)
  {
  ArrayFree(m_buffers);
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

   for(uint i=0; i<size; i++) {
      m_params[i+1].type=TYPE_DOUBLE;
      m_params[i+1].double_value=inputs[i];
   }
}

void CCustomSignal::IndicatorFile(string filename)               {
   m_indicator_file=filename;
   if (ArraySize(m_params) > 0) { // the Params where already generated. so we overwrite it in the params as well
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

bool CCustomSignal::Update(void) {
   m_sig_direction = LongSignal() ? 1 :
      ShortSignal() ? -1 : 0;
   return UpdateSide();
}

bool CCustomSignal::UpdateSide(void) {
   m_side = LongSide() ? 1 :
      ShortSide() ? -1 : 0;
   return true;
}

bool CCustomSignal::GetIndiBuffers(datetime date_start, uint idx, double &indi_buf[]) {
   datetime date_finish; // data copying end date
   // bool     sign_buf[]; // signal array (true - buy, false - sell)
   // datetime time_buf[]; // array of signals' arrival time
   // int      sign_size=0; // signal array size
   // double   indi_buf[][]; // array of indicator values
   //datetime date_buf[]; // array of indicator dates
   int      indi_size=0; // size of indicator arrays
   date_finish=TimeCurrent();
//--- being in the loop until the indicator calculates all its values
   while(BarsCalculated(m_indicator.Handle())==-1)
      Sleep(10); // pause to allow the indicator to calculate all its values
//--- copy the indicator values for a certain period of time
   ResetLastError();
   if(CopyBuffer(m_indicator.Handle(),m_buffers[idx],date_start,date_finish,indi_buf)==-1) {
      PrintFormat("Failed to copy indicator values. Error code = %d",GetLastError());
      return false;
   }

   return true;
}

bool CCustomSignal::AddBuffersToFrame(datetime date_start) {
   datetime date_finish=TimeCurrent();

   for (int i=0; i<5; i++) {
      if (m_buffers[i] >= 0) {
         double   indi_buf[];

         ResetLastError();
         if(CopyBuffer(m_indicator.Handle(),m_buffers[i],date_start,date_finish,indi_buf)==-1) {
            PrintFormat("Failed to copy indicator values. Error code = %d",GetLastError());
            return false;
         }
         // if (!GetIndiBuffers(date_start, i, indi_buf))
         //       return false;
         PrintFormat("size of indi buffer array %d",ArraySize(indi_buf));


         ResetLastError();
         if(!FrameAdd(m_symbol.Name(), 0, i, indi_buf)) {
            Print("Frame add error: ", GetLastError());
            return false;
         }
      }
   }
   return true;
}

bool CCustomSignal::AddSideChangeToFrame() {
   datetime date_finish=TimeCurrent();

   int last_side = m_side;
   UpdateSide();
   if (last_side != m_side) {
      // write side change with date to Frame
      // Print("Side changed: ", last_side, " -> ", m_side);

      datetime date;
      if(!SeriesInfoInteger(m_symbol.Name(),m_period,SERIES_LASTBAR_DATE,date))
      { // If request has failed, print error message:
         Print(__FUNCTION__+" Error when getting time of last bar opening: "+IntegerToString(GetLastError()));
         return(0);
      }

      ResetLastError();
      if(!FrameAdd(m_symbol.Name(),
                   0,  // func not implemented
                   m_side, date)) {
         Print("Frame add error: ", IntegerToString(GetLastError()));
         return false;
      }
   }
   return true;
}

bool CCustomSignal::WriteBuffersToFile(datetime start_date, string filename) {
   datetime date_finish; // data copying end date
   // bool     sign_buf[]; // signal array (true - buy, false - sell)
   // datetime time_buf[]; // array of signals' arrival time
   // int      sign_size=0; // signal array size
   double   indi_buf[]; // array of indicator values
   datetime date_buf[]; // array of indicator dates
   int      indi_size=0; // size of indicator arrays
//--- end time is the current time
   date_finish=TimeCurrent();
//--- being in the loop until the indicator calculates all its values
   while(BarsCalculated(m_indicator.Handle())==-1)
      Sleep(10); // pause to allow the indicator to calculate all its values
//--- copy the indicator values for a certain period of time
   ResetLastError();
   if(CopyBuffer(m_indicator.Handle(),m_buffers[0],start_date,date_finish,indi_buf)==-1) {
      PrintFormat("Failed to copy indicator values. Error code = %d",GetLastError());
      return false;
   }
//--- copy the appropriate time for the indicator values
   ResetLastError();
   if(CopyTime(m_symbol.Name(),m_period,start_date,date_finish,date_buf)==-1) {

      PrintFormat("Failed to copy time values. Error code = %d",GetLastError());
      return false;
   }
// //--- free the memory occupied by the indicator
//    IndicatorRelease(m_indicator);
// //--- receive the bufer size
   indi_size=ArraySize(indi_buf);
// //--- analyze the data and save the indicator signals to the arrays
//    ArrayResize(sign_buf,indi_size-1);
//    ArrayResize(time_buf,indi_size-1);
//    for(int i=1;i<indi_size;i++)
//      {
//       //--- buy signal
//       if(indi_buf[i-1]<0 && indi_buf[i]>=0)
//         {
//          sign_buf[sign_size]=true;
//          time_buf[sign_size]=date_buf[i];
//          sign_size++;
//         }
//       //--- sell signal
//       if(indi_buf[i-1]>0 && indi_buf[i]<=0)
//         {
//          sign_buf[sign_size]=false;
//          time_buf[sign_size]=date_buf[i];
//          sign_size++;
//         }
//      }
//--- open the file for writing the indicator values (if the file is absent, it will be created automatically)
   ResetLastError();
   int file_handle=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_CSV);
   if(file_handle!=INVALID_HANDLE) {
      PrintFormat("%s file is available for writing",filename);
      PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
      //--- first, write the number of signals
      FileWrite(file_handle,indi_size);
      //--- write the time and values of signals to the file
      for(int i=0;i<indi_size;i++)
         FileWrite(file_handle,date_buf[i],indi_buf[i]);
      //--- close the file
      FileClose(file_handle);
      PrintFormat("Data is written, %s file is closed",filename);
   }
   else {
      PrintFormat("Failed to open %s file, Error code = %d",filename,GetLastError());
      return false;
   }

   return true;
}
