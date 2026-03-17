"""
Tests for the new diagnostic features: PPS and Activity status.
"""

import threading

from helpers import make_test_config
import pytest

from serial_handler import TaskReadSerial
import state as state_module


class TestDiagnostics:
    """Test Suite for PPS and Activity signaling."""

    @pytest.fixture
    def task(self):
        context = state_module.get_context()
        context.config = make_test_config()
        context.state.reset_state()
        return TaskReadSerial(context, threading.Event(), threading.Event())

    def test_pps_calculation(self, task):
        """Test that pulses per second (PPS) is correctly calculated."""
        context = task.app_context
        # 10 pulses in 10 seconds = 1.0 PPS
        task._update_meter(1, 110, 10, 10)
        assert context.state.meters[1].pps == 1.0

        # 5 pulses in 20 seconds = 0.25 PPS
        task._update_meter(1, 115, 5, 20)
        assert context.state.meters[1].pps == 0.25

        # 0 pulses = 0 PPS
        task._update_meter(1, 115, 0, 10)
        assert context.state.meters[1].pps == 0.0

    def test_activity_signaling(self, task):
        """Test that activity flag is set correctly based on pulses in interval."""
        context = task.app_context

        # Pulses received -> activity true
        task._update_meter(1, 110, 5, 10)
        assert context.state.meters[1].activity is True

        # No pulses -> activity false
        task._update_meter(1, 110, 0, 10)
        assert context.state.meters[1].activity is False

    def test_pps_rounding(self, task):
        """Test that PPS is rounded to 3 decimal places."""
        # 1 pulse in 3 seconds = 0.33333... -> 0.333
        task._update_meter(1, 101, 1, 3)
        assert task.app_context.state.meters[1].pps == 0.333
