//+------------------------------------------------------------------+

//|                                     Copyright 2019, Stefan Lendl |

//+------------------------------------------------------------------+

#include "SaturationSignal.mqh"

//+------------------------------------------------------------------+



class CBothLinesSaturationLevelsSignal : public CSaturationSignal {

protected:

  CIndicatorBuffer *m_buf_up;

  CIndicatorBuffer *m_buf_down;

  double m_level_up_enter;

  double m_level_down_enter;



protected:

  virtual bool InitIndicatorBuffers();

  virtual ENUM_REGION UpdateRegion();

};



ENUM_REGION CBothLinesSaturationLevelsSignal::UpdateRegion() {

  int idx = StartIndex();

  // only update if both lines are in the given region

  // if not keep the region state

  if (m_buf_up.At(idx) > m_level_up_enter &&

      m_buf_down.At(idx) > m_level_up_enter) {

    m_region = LongRegion;

  } else if (m_buf_up.At(idx) <= m_level_down_enter &&

             m_buf_down.At(idx) <= m_level_down_enter) {

    m_region = ShortRegion;

  } else if (m_buf_up.At(idx) <= m_level_up_enter &&

             m_buf_down.At(idx) <= m_level_up_enter &&

             m_buf_up.At(idx) > m_level_down_enter &&

             m_buf_down.At(idx) > m_level_down_enter) {

    m_region = NeutralRegion;

  }

  return m_region;

}



bool CBothLinesSaturationLevelsSignal::InitIndicatorBuffers() {

  m_buf_up = m_indicator.At(m_buffers[0]);

  m_buf_down = m_indicator.At(m_buffers[1]);

  m_level_up_enter = m_config[0];

  m_level_down_enter = m_config[1];

  m_signal_on_region_leave = m_config[2];

  return true;

}

