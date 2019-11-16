//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CTwoLinesCrossSignal : public CCustomSignal
  {
protected:
   uint              m_up_buf;
   uint              m_down_buf;

public:
   //--- methods of checking if the market models are formed
   virtual bool      LongSide(void);
   virtual bool      ShortSide(void) { return !LongSide(); }
   virtual bool      LongSignal(void);
   virtual bool      ShortSignal(void);
  };

/* TODO
use smth like:
double CiBearsPower::Main(const int index) const
  {
   CIndicatorBuffer *buffer=At(0);
//--- check
   if(buffer==NULL)
      return(EMPTY_VALUE);
//---
   return(buffer.At(index));
  }
*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTwoLinesCrossSignal::LongSide(void)
  {
   int idx = StartIndex();
   double up = m_indicator.GetData(m_up_buf,idx);
   double down = m_indicator.GetData(m_down_buf,idx);

//--- return the result
   return (up >= down);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTwoLinesCrossSignal::LongSignal(void)
  {
   int idx = StartIndex();
   double up = m_indicator.GetData(m_up_buf,idx);
   double down = m_indicator.GetData(m_down_buf,idx);
   double up_last = m_indicator.GetData(m_up_buf,idx+1);
   double down_last = m_indicator.GetData(m_down_buf,idx+1);

//--- return the result
   return (up >= down && up_last < down_last);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTwoLinesCrossSignal::ShortSignal(void)
  {
   int idx = StartIndex();
   double up = m_indicator.GetData(m_up_buf,idx);
   double down = m_indicator.GetData(m_down_buf,idx);
   double up_last = m_indicator.GetData(m_up_buf,idx+1);
   double down_last = m_indicator.GetData(m_down_buf,idx+1);

//--- return the result
   return (up < down && up_last >= down_last);
  }
//+------------------------------------------------------------------+
