//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CColorChangeSignal : public CCustomSignal
  {
protected:
   uint              m_buf_idx;
   uint              m_down_idx;
   CIndicatorBuffer *m_buf_up;
   CIndicatorBuffer *m_buf_down;
   uint              m_color_neutr;
   uint              m_color_up;
   uint              m_color_down;

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

bool CColorChangeSignal::LongSignal(void)
  {
   double color_idx=m_buf_up.At(m_Idx);
   double color_idx_last=m_buf_up.At(m_Idx+1);
   if ((color_idx_last == m_color_down || color_idx_last == m_color_neutr)
       && color_idx == m_color_up) {
      return true;
   }
   return false;
  }

bool CColorChangeSignal::LongExit(void)
  {
   double color_idx=m_buf_up.At(m_Idx);
   double color_idx_last=m_buf_up.At(m_Idx+1);
   if (color_idx_last == m_color_up &&
       (color_idx == m_color_neutr || color_idx == m_color_down))
      return true;
   return false;
  }

bool CColorChangeSignal::LongSide(void) {
   double color_idx=m_buf_up.At(m_Idx);
   if (color_idx == m_color_up)
      return true;
   return false;
}

bool CColorChangeSignal::ShortSide(void) {
   double color_idx=m_buf_down.At(m_Idx);
   if (color_idx == m_color_down)
      return true;
   return false;
}

bool CColorChangeSignal::ShortSignal(void)
  {
   double color_idx=m_buf_down.At(m_Idx);
   double color_idx_last=m_buf_down.At(m_Idx+1);
   if ((color_idx_last == m_color_up || color_idx_last == m_color_neutr)
       && color_idx == m_color_down)
      return true;
   return false;
  }

bool CColorChangeSignal::ShortExit(void)
  {
   double color_idx=m_buf_down.At(m_Idx);
   double color_idx_last=m_buf_down.At(m_Idx+1);
   if (color_idx_last == m_color_down &&
       (color_idx == m_color_neutr || color_idx == m_color_up))
      return true;
   return false;
  }

bool CColorChangeSignal::InitIndicatorBuffers()
  {
   m_buf_up = m_indicator.At(m_buf_idx);
   m_buf_down = m_indicator.At(m_down_idx);
   return true;
  }
