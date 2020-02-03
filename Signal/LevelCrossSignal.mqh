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
   bool  m_strict_side;  // Side considers the enter or the exit values
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

protected:
   virtual bool      InitIndicatorBuffers();
  };

bool CLevelCrossSignal::LongSide(void)
  {
   int idx = StartIndex();
   // Side needs to evaluate after Signal, otherwise this is not set
   if (m_last_signal <= 0)     // if the last Signal was not long
     return false;
   if (m_strict_side)          // only on the Side if we're in the extreme zone
     return (m_buf_up.At(idx) > m_level_up_enter);
   if (m_level_up_exit > m_level_up_enter)
     return (m_buf_up.At(idx) > m_level_up_exit);   // we have not hit exit yet
                                                    // if up_exit and down_enter are the same this is pretty much the same as considering last_signal only
            //  && m_buf_up.At(idx) > m_level_down_enter);  // we have not hit the short entry yet. ... this already represented by m_last_signal
   return m_last_signal;
  }

bool CLevelCrossSignal::ShortSide(void)
  {
   int idx = StartIndex();
   if (m_last_signal >= 0) // if the last Signal was not short
     return false;
   if (m_strict_side)       // only on the Side if we're in the extreme zone
     return (m_buf_up.At(idx) >= m_level_down_enter);
   if (m_level_down_exit < m_level_down_enter)
     return (m_buf_up.At(idx) >= m_level_down_exit);
   return m_last_signal;
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
   m_last_signal = 0;
   if (m_level_down_enter >= m_level_up_enter)
     m_strict_side = false;

   return true;
}
