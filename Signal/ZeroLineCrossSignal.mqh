//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CZeroLineCrossSignal : public CCustomSignal
  {
protected:
   uint m_buf_idx;
   CIndicatorBuffer *m_buf;
   
public:
   //--- methods of checking if the market models are formed
   virtual bool      LongSide(void);
   virtual bool      ShortSide(void) { return !LongSide(); }
   virtual bool      LongSignal(void);
   virtual bool      ShortSignal(void);

   void Buffer(uint buf);

protected:
   virtual bool      InitIndicatorBuffers();
  };

void CZeroLineCrossSignal::Buffer(uint buf) {
   m_buf_idx = buf;
   m_buf = m_indicator.At(m_buf_idx);
}
  
bool CZeroLineCrossSignal::LongSide(void)
  {
   int idx = StartIndex();
   return (m_buf.At(idx) > 0);
  }

bool CZeroLineCrossSignal::LongSignal(void)
  {
   int idx = StartIndex();
   return (m_buf.At(idx) > 0 && m_buf.At(idx+1) <= 0);
  }

bool CZeroLineCrossSignal::ShortSignal(void)
  {
   int idx = StartIndex();
   return (m_buf.At(idx) <= 0 && m_buf.At(idx+1) > 0);
  }

bool CZeroLineCrossSignal::InitIndicatorBuffers()
{
   m_buf = m_indicator.At(m_buf_idx);
   return true;
}
