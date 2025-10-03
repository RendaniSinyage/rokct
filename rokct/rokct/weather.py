# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import requests
import time
import logging

class WeatherService:
    def __init__(self):
        self.api_key = frappe.get_doc("Weather Settings").get_password("weatherapi_com_api_key")
        if not self.api_key:
            raise Exception("Weather API key is not set in Weather Settings")
        self.base_url = "http://api.weatherapi.com/v1"
        self.max_retries = 3
        self.retry_delay = 1  # seconds
        self.retryable_status_codes = [502, 503, 504]

    def get_forecast(self, location):
        # The Laravel example included location parsing logic.
        # The weatherapi.com 'q' param is flexible, but we will mimic the logic.
        city, country = self._parse_location(location)
        search_query = f"{city},{country}" if country else city

        return self._fetch_from_api_with_retry(search_query, 3, "yes")

    def _parse_location(self, location):
        parts = [part.strip() for part in location.lower().split(',')]
        city = parts[0]
        country = parts[1] if len(parts) > 1 else ''
        return city, country

    def _fetch_from_api_with_retry(self, location_query, days, alerts):
        last_exception = None
        for attempt in range(self.max_retries):
            try:
                params = {
                    "key": self.api_key,
                    "q": location_query,
                    "days": days,
                    "alerts": alerts
                }
                response = requests.get(f"{self.base_url}/forecast.json", params=params, timeout=15)
                response.raise_for_status()
                return response.json()

            except requests.exceptions.HTTPError as e:
                last_exception = e
                if e.response.status_code in self.retryable_status_codes:
                    if attempt < self.max_retries - 1:
                        # Exponential backoff: 1s, 2s, 4s
                        delay = self.retry_delay * (2 ** attempt)
                        logging.warning(f"Weather API attempt {attempt + 1} failed with status {e.response.status_code}. Retrying in {delay}s...")
                        time.sleep(delay)
                        continue
                else:
                    # Non-retryable HTTP error
                    logging.error(f"Weather API request failed with status {e.response.status_code}: {e.response.text}")
                    raise e

            except requests.exceptions.RequestException as e:
                # Includes connection errors, timeouts, etc.
                last_exception = e
                if attempt < self.max_retries - 1:
                    delay = self.retry_delay * (2 ** attempt)
                    logging.warning(f"Weather API attempt {attempt + 1} failed: {e}. Retrying in {delay}s...")
                    time.sleep(delay)
                    continue

        logging.error(f"Weather API call failed after {self.max_retries} attempts.")
        raise last_exception

def get_weather_data(location):
    """Public function to be called by the API layer."""
    service = WeatherService()
    return service.get_forecast(location)

