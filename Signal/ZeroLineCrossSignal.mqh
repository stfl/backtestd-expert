//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CZeroLineCrossSignal : public CCustomSignal
  {
protected:
   uint m_up_buf;
   
public:
                     CZeroLineCrossSignal(void);
                    ~CZeroLineCrossSignal(void);
   //--- methods of checking if the market models are formed
   // virtual bool LongSide(void);
   virtual bool ShortSide(void) { return !LongSide(); } 
   // virtual bool LongSignal(void);
   // virtual bool ShortSignal(void);
  };
  
bool CZeroLineCrossSignal::LongSide(void)
  {
   int idx = StartIndex();
   double up = m_indicator.GetData(m_up_buf,idx);
  
   //--- return the result
   return (up > 0);
  }

bool CZeroLineCrossSignal::LongSignal(void)
  {
   int idx = StartIndex();
   double up = m_indicator.GetData(m_up_buf,idx);
   double up_last = m_indicator.GetData(m_up_buf,idx+1);
  
   //--- return the result
   return (up > 0 && up_last <= 0);
  }

bool CZeroLineCrossSignal::ShortSignal(void)
  {
   int idx = StartIndex();
   double up = m_indicator.GetData(m_up_buf,idx);
   double up_last = m_indicator.GetData(m_up_buf,idx+1);
  
   //--- return the result
   return (up <= 0 && up_last > 0);
  }
