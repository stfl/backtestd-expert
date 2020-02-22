//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CLevelCrossSignal : public CCustomSignal
  {
protected:
   uint m_buf_idx;
   uint m_down_idx;
   CIndicatorBuffer *m_buf_up;
   CIndicatorBuffer *m_buf_down;
   double m_level_up_enter;
   double m_level_up_exit;
   double m_level_down_enter;
   double m_level_down_exit;
   bool  m_stateful_side;      // Side considers the enter or the exit values
   int   m_last_signal;

   //                                  strict = true            strict == false
   //                                  x <- LongSide            x <- LongSide
   // Level Up enter   ▲----
   //                                  x <- None                ▼ <- LongSide
   // Level Up exit    ▼----
   //                                  x <- None                x <- None
   // Level Down exit  ▲----
   //                                  x <- None                ▲ <- ShortSide
   // Level Down enter ▼----
   //                                  x <- ShortSide           x <- ShortSide


   // if down enter is higher than up enter
   // his case always represents non strict side
   //                                                x  LongSide
   // Level Down enter == Down exit  ▼----
   //                                                ▼ LongSide  ▲ ShortSide
   // Level Up enter == Up exit      ▲----
   //                                                x <- ShortSide

public:
   //--- methods of checking if the market models are formed
   virtual bool      LongSide(void);
   virtual bool      ShortSide(void);
   virtual bool      LongSignal(void);
   virtual bool      ShortSignal(void);
   virtual bool      LongExit(void);
   virtual bool      ShortExit(void);
   
                     CLevelCrossSignal(void);

protected:
   virtual bool      InitIndicatorBuffers();
  };
  
CLevelCrossSignal::CLevelCrossSignal(void) {
   m_stateful_side = false;
   m_last_signal = 0;
}

bool CLevelCrossSignal::LongSide(void)
  {
   int idx = StartIndex();
   if (m_stateful_side) {
      LongSignal();                 // calculate Signal in case we don't have m_last_signal set yet.
      return m_last_signal > 0;     // consider the last signal
   } else {
      return m_buf_up.At(idx) > m_level_up_enter;
   }
  }

bool CLevelCrossSignal::ShortSide(void)
  {
   int idx = StartIndex();
   if (m_stateful_side) {
      ShortSignal();                 // calculate Signal in case we don't have m_last_signal set yet.
      return m_last_signal < 0;     // consider the last signal
   } else {
      return m_buf_down.At(idx) < m_level_down_enter;
   }
  }

bool CLevelCrossSignal::LongSignal(void)
  {
   int idx = StartIndex();
   bool signal = (m_buf_up.At(idx) > m_level_up_enter &&
                  m_buf_up.At(idx + 1) <= m_level_up_enter);
   if (signal)
      m_last_signal = 100;
   return signal;
  }

bool CLevelCrossSignal::LongExit(void)
  {
   int idx = StartIndex();
   return (ShortSignal() || (
           m_buf_up.At(idx) <= m_level_up_exit &&
           m_buf_up.At(idx + 1) > m_level_up_exit));
  }

bool CLevelCrossSignal::ShortSignal(void)
  {
   int idx = StartIndex();
   bool signal = (m_buf_down.At(idx) <= m_level_down_enter &&
                  m_buf_down.At(idx + 1) > m_level_down_enter);
   if (signal)
      m_last_signal = -100;
   return signal;
  }

bool CLevelCrossSignal::ShortExit(void)
  {
   int idx = StartIndex();
   return (LongSignal() ||
           (m_buf_down.At(idx) > m_level_down_exit &&
           m_buf_down.At(idx + 1) <= m_level_down_exit));
  }

bool CLevelCrossSignal::InitIndicatorBuffers()
{
   m_buf_up = m_indicator.At(m_buf_idx);
   m_buf_down = m_indicator.At(m_down_idx);
   return true;
}
