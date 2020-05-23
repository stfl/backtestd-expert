//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CTwoLinesColorChangeSignal : public CCustomSignal
  {
protected:
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

bool CTwoLinesColorChangeSignal::LongSignal(void)
  {
   double color_idx=m_buf_up.At(m_Idx);
   double color_idx_last=m_buf_up.At(m_Idx+1);
   if ((color_idx_last == m_color_down || color_idx_last == m_color_neutr)
       && color_idx == m_color_up) {
      return true;
   }
   return false;
  }

bool CTwoLinesColorChangeSignal::LongExit(void)
  {
   double color_idx=m_buf_up.At(m_Idx);
   double color_idx_last=m_buf_up.At(m_Idx+1);
   if (color_idx_last == m_color_up &&
       (color_idx == m_color_neutr || color_idx == m_color_down))
      return true;
   return false;
  }

bool CTwoLinesColorChangeSignal::LongSide(void) {
   double color_idx=m_buf_up.At(m_Idx);
   if (color_idx == m_color_up)
      return true;
   return false;
}

bool CTwoLinesColorChangeSignal::ShortSide(void) {
   double color_idx=m_buf_down.At(m_Idx);
   if (color_idx == m_color_down)
      return true;
   return false;
}

bool CTwoLinesColorChangeSignal::ShortSignal(void)
  {
   double color_idx=m_buf_down.At(m_Idx);
   double color_idx_last=m_buf_down.At(m_Idx+1);
   if ((color_idx_last == m_color_up || color_idx_last == m_color_neutr)
       && color_idx == m_color_down)
      return true;
   return false;
  }

bool CTwoLinesColorChangeSignal::ShortExit(void)
  {
   double color_idx=m_buf_down.At(m_Idx);
   double color_idx_last=m_buf_down.At(m_Idx+1);
   if (color_idx_last == m_color_down &&
       (color_idx == m_color_neutr || color_idx == m_color_up))
      return true;
   return false;
  }

bool CTwoLinesColorChangeSignal::InitIndicatorBuffers()
  {
   m_buf_up = m_indicator.At(m_buffers[0]);
   m_buf_down = m_indicator.At(m_buffers[1]);
   m_color_neutr = (uint)m_config[0];
   m_color_up = (uint)m_config[1];
   m_color_down = (uint)m_config[2];
   return true;
  }
