//+------------------------------------------------------------------+
//|                                                    SignalTCT.mqh |
//|                                     Copyright 2019, Stefan Lendl |
//|                                                                  |
//+------------------------------------------------------------------+
#include <backtestd\SignalClass\CustomSignal.mqh>

#define PRODUCE_SignalTCT

// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator 'Adaptive Moving Average'             |
//| Type=SignalAdvanced                                              |
//| Name=Adaptive Moving Average                                     |
//| ShortName=AMA                                                    |
//| Class=CSignalTCT                                                 |
//| Page=signal_ama                                                  |
//| Parameter=PeriodMA,int,10,Period of averaging                    |
//| Parameter=PeriodFast,int,2,Period of fast EMA                    |
//| Parameter=PeriodSlow,int,30,Period of slow EMA                   |
//| Parameter=Shift,int,0,Time shift                                 |
//| Parameter=Applied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Prices series   |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalTCT.                                                |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Adaptive Moving Average' indicator.                |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CSignalTCT : public CCustomSignal
  {
public:
                     CSignalTCT(void);
                    ~CSignalTCT(void);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalTCT::CSignalTCT(void)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
//m_used_series=USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalTCT::~CSignalTCT(void)
  {
  }
//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalTCT::LongCondition(void)
  {
   int result= 0;
   int idx = StartIndex();
   double up = m_indicator.GetData(0,idx);
   double up_last=m_indicator.GetData(0,idx+1);
   double down=m_indicator.GetData(1,idx);
   double down_last=m_indicator.GetData(1,idx+1);
   
      //Print("StartIndex: ", idx);
   //printf("Open: %f Close: %f High: %f Low: %f", Open(idx),Close(idx),High(idx),Low(idx));

   Print(TimeCurrent(),": ",up_last," ", down_last," > ",up, " ", down);
   if(up>down && up_last<down_last)
     {
      printf("(%f , %f) > (%f , %f) >> Long",up_last,down_last,up,down);
      result=100;
     }

//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalTCT::ShortCondition(void)
  {
   int result= 0;
   int idx = StartIndex();
   double up = m_indicator.GetData(0,idx);
   double up_last=m_indicator.GetData(0,idx+1);
   double down=m_indicator.GetData(1,idx);
   double down_last=m_indicator.GetData(1,idx+1);
   
   if(up<down && up_last>down_last)
     {
      printf("(%f , %f) > (%f , %f) >> Short",up_last,down_last,up,down);
      result=100;
     }
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
