#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: RFNoC: conv32Bto2B Example
# GNU Radio version: v3.8.5.0-5-g982205bd

from distutils.version import StrictVersion

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print("Warning: failed to XInitThreads()")

from PyQt5 import Qt
from gnuradio import eng_notation
from gnuradio import analog
from gnuradio import gr
from gnuradio.filter import firdes
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio.qtgui import Range, RangeWidget
import ettus
from gnuradio import uhd
import qpsk

from gnuradio import qtgui

class rfnoc_conv32Bto2B(gr.top_block, Qt.QWidget):

    def __init__(self):
        gr.top_block.__init__(self, "RFNoC: conv32Bto2B Example")
        Qt.QWidget.__init__(self)
        self.setWindowTitle("RFNoC: conv32Bto2B Example")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except:
            pass
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("GNU Radio", "rfnoc_conv32Bto2B")

        try:
            if StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
                self.restoreGeometry(self.settings.value("geometry").toByteArray())
            else:
                self.restoreGeometry(self.settings.value("geometry"))
        except:
            pass

        ##################################################
        # Variables
        ##################################################
        self.samp_rate = samp_rate = 10e6/2/16
        self.variable_qtgui_range_user_reg = variable_qtgui_range_user_reg = 1
        self.variable_qtgui_range_freq = variable_qtgui_range_freq = samp_rate/10
        self.variable_qtgui_range_amplitude = variable_qtgui_range_amplitude = 1
        self.rfnoc_graph = ettus_rfnoc_graph = ettus.rfnoc_graph(uhd.device_addr(",".join(('', 'type=x300'))))

        ##################################################
        # Blocks
        ##################################################
        self._samp_rate_tool_bar = Qt.QToolBar(self)
        self._samp_rate_tool_bar.addWidget(Qt.QLabel('Sampling Rate (Hz)' + ": "))
        self._samp_rate_line_edit = Qt.QLineEdit(str(self.samp_rate))
        self._samp_rate_tool_bar.addWidget(self._samp_rate_line_edit)
        self._samp_rate_line_edit.returnPressed.connect(
            lambda: self.set_samp_rate(eng_notation.str_to_num(str(self._samp_rate_line_edit.text()))))
        self.top_layout.addWidget(self._samp_rate_tool_bar)
        self._variable_qtgui_range_user_reg_range = Range(-2**15-1, 2**15-1, 1, 1, 1000)
        self._variable_qtgui_range_user_reg_win = RangeWidget(self._variable_qtgui_range_user_reg_range, self.set_variable_qtgui_range_user_reg, 'User Reg', "counter_slider", int)
        self.top_layout.addWidget(self._variable_qtgui_range_user_reg_win)
        self._variable_qtgui_range_freq_range = Range(-samp_rate/2, samp_rate/2, samp_rate/1000, samp_rate/10, 1000)
        self._variable_qtgui_range_freq_win = RangeWidget(self._variable_qtgui_range_freq_range, self.set_variable_qtgui_range_freq, 'Frequency', "counter_slider", float)
        self.top_layout.addWidget(self._variable_qtgui_range_freq_win)
        self._variable_qtgui_range_amplitude_range = Range(0, 1, 1/1000, 1, 1000)
        self._variable_qtgui_range_amplitude_win = RangeWidget(self._variable_qtgui_range_amplitude_range, self.set_variable_qtgui_range_amplitude, 'Amplitude', "counter_slider", float)
        self.top_layout.addWidget(self._variable_qtgui_range_amplitude_win)
        self.qpsk_conv32Bto2B_0 = qpsk.conv32Bto2B(
          self.rfnoc_graph,
          uhd.device_addr(''),
          -1,
          -1)
        self.qpsk_conv32Bto2B_0.set_int_property('user_reg', 0)
        self.ettus_rfnoc_tx_streamer_0 = ettus.rfnoc_tx_streamer(
            self.rfnoc_graph,
            1,
            uhd.stream_args(
                cpu_format="fc32",
                otw_format="sc16",
                channels=[],
                args='',
            ),
            1
        )
        self.ettus_rfnoc_tx_radio_0 = ettus.rfnoc_tx_radio(
            self.rfnoc_graph,
            uhd.device_addr(''),
            -1,
            -1)
        self.ettus_rfnoc_tx_radio_0.set_rate(samp_rate)
        self.ettus_rfnoc_tx_radio_0.set_antenna('TX/RX', 0)
        self.ettus_rfnoc_tx_radio_0.set_frequency(1.2e9, 0)
        self.ettus_rfnoc_tx_radio_0.set_gain(70, 0)
        self.ettus_rfnoc_tx_radio_0.set_bandwidth(0, 0)
        self.ettus_rfnoc_duc_0 = ettus.rfnoc_duc(
            self.rfnoc_graph,
            uhd.device_addr(''),
            -1,
            -1)
        self.ettus_rfnoc_duc_0.set_freq(0, 0)
        self.ettus_rfnoc_duc_0.set_input_rate(samp_rate*16*4, 0)
        self.analog_noise_source_x_0 = analog.noise_source_c(analog.GR_GAUSSIAN, 1, 0)


        ##################################################
        # Connections
        ##################################################
        self.rfnoc_graph.connect(self.ettus_rfnoc_duc_0.get_unique_id(), 0, self.ettus_rfnoc_tx_radio_0.get_unique_id(), 0, False)
        self.rfnoc_graph.connect(self.ettus_rfnoc_tx_streamer_0.get_unique_id(), 0, self.qpsk_conv32Bto2B_0.get_unique_id(), 0, False)
        self.rfnoc_graph.connect(self.qpsk_conv32Bto2B_0.get_unique_id(), 0, self.ettus_rfnoc_duc_0.get_unique_id(), 0, False)
        self.connect((self.analog_noise_source_x_0, 0), (self.ettus_rfnoc_tx_streamer_0, 0))


    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "rfnoc_conv32Bto2B")
        self.settings.setValue("geometry", self.saveGeometry())
        event.accept()

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        Qt.QMetaObject.invokeMethod(self._samp_rate_line_edit, "setText", Qt.Q_ARG("QString", eng_notation.num_to_str(self.samp_rate)))
        self.set_variable_qtgui_range_freq(self.samp_rate/10)
        self.ettus_rfnoc_duc_0.set_input_rate(self.samp_rate*16*4, 0)
        self.ettus_rfnoc_tx_radio_0.set_rate(self.samp_rate)

    def get_variable_qtgui_range_user_reg(self):
        return self.variable_qtgui_range_user_reg

    def set_variable_qtgui_range_user_reg(self, variable_qtgui_range_user_reg):
        self.variable_qtgui_range_user_reg = variable_qtgui_range_user_reg

    def get_variable_qtgui_range_freq(self):
        return self.variable_qtgui_range_freq

    def set_variable_qtgui_range_freq(self, variable_qtgui_range_freq):
        self.variable_qtgui_range_freq = variable_qtgui_range_freq

    def get_variable_qtgui_range_amplitude(self):
        return self.variable_qtgui_range_amplitude

    def set_variable_qtgui_range_amplitude(self, variable_qtgui_range_amplitude):
        self.variable_qtgui_range_amplitude = variable_qtgui_range_amplitude

    def get_ettus_rfnoc_graph(self):
        return self.ettus_rfnoc_graph

    def set_ettus_rfnoc_graph(self, ettus_rfnoc_graph):
        self.ettus_rfnoc_graph = ettus_rfnoc_graph





def main(top_block_cls=rfnoc_conv32Bto2B, options=None):

    if StrictVersion("4.5.0") <= StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
        style = gr.prefs().get_string('qtgui', 'style', 'raster')
        Qt.QApplication.setGraphicsSystem(style)
    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls()

    tb.start()

    tb.show()

    def sig_handler(sig=None, frame=None):
        Qt.QApplication.quit()

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    timer = Qt.QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None)

    def quitting():
        tb.stop()
        tb.wait()

    qapp.aboutToQuit.connect(quitting)
    qapp.exec_()

if __name__ == '__main__':
    main()
