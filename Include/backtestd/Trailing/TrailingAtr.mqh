//+------------------------------------------------------------------+
//|                   Copyright 2020, Stefan Lendl
//+------------------------------------------------------------------+
#include <Expert\ExpertTrailing.mqh>
class CTrailingAtr : public CExpertTrailing
{
protected:
   double            m_stop_level_atr_multiplier;
   CiATR             m_atr;
   int               m_atr_period;

   bool              AddAtr(int atr_period);

public:
                     CTrailingAtr::CTrailingAtr(double atr_multiplier, CiATR *atr_handle);
                     CTrailingAtr::CTrailingAtr(double atr_multiplier, int atr_period);
                    ~CTrailingAtr(void);
   virtual bool      Init(CSymbolInfo *symbol,ENUM_TIMEFRAMES period,double point);

   //--- methods of initialization of protected data
   void              StopLevelAtrMultiplier(int atr_multiplier)     { m_stop_level_atr_multiplier=atr_multiplier;     }
   virtual bool      ValidationSettings(void);
   virtual bool      CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp);
   virtual bool      CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp);
   void              Refresh() { m_atr.Refresh(); }
};

// CTrailingAtr::CTrailingAtr(void) : m_stop_level_atr_multiplier(2.5) {}
  
// CTrailingAtr::CTrailingAtr(double atr_multiplier, CiATR *atr_handle) {
//    m_stop_level_atr_multiplier = atr_multiplier;
//    m_atr = atr_handle;
// }

CTrailingAtr::CTrailingAtr(double atr_multiplier, int atr_period) {
   m_stop_level_atr_multiplier = atr_multiplier;
   m_atr_period = atr_period;
}

CTrailingAtr::~CTrailingAtr(void) {
}

bool CTrailingAtr::Init(CSymbolInfo *symbol,ENUM_TIMEFRAMES period,double point) {
   bool res = true;
   res &= CExpertBase::Init(symbol, period, point);
   res &= AddAtr(m_atr_period);
   return res;
}

bool CTrailingAtr::AddAtr(int atr_period) {
   if(!m_atr.Create(m_symbol.Name(),m_period,atr_period))
      return false;
   return true;
}

bool CTrailingAtr::ValidationSettings(void) {
   if(!CExpertTrailing::ValidationSettings())
      return(false);
   if(m_stop_level_atr_multiplier<=0) {
      printf(__FUNCTION__+": trailing Stop ATR multiplier must be greater than 0");
      return(false);
   }
   if(m_atr_period <= 0) {
      printf(__FUNCTION__+": trailing ATR period must be greater than 0");
      return(false);
   }
   return(true);
}

//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for long position.          |
//+------------------------------------------------------------------+
bool CTrailingAtr::CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp) {
   if(position==NULL)
      return(false);
   Refresh();

   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
   double price =m_symbol.Bid();


   double atr_value = m_atr.Main(m_every_tick ? 0 : 1);
   double new_sl = price - (m_stop_level_atr_multiplier * atr_value);

   sl=EMPTY_VALUE;
   if (new_sl > pos_sl) {
      sl = new_sl;
   }

   return(sl!=EMPTY_VALUE);
}

//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for short position.         |
//+------------------------------------------------------------------+
bool CTrailingAtr::CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp) {
   if(position==NULL)
      return(false);
   Refresh();

   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
   double price =m_symbol.Ask();

   double atr_value = m_atr.Main(m_every_tick ? 0 : 1);
   double new_sl = price + (m_stop_level_atr_multiplier * atr_value);

   sl=EMPTY_VALUE;
   if (new_sl < pos_sl) {
      sl = new_sl;
   }

   return(sl!=EMPTY_VALUE);
}
