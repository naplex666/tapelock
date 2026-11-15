"""Record the TapeLock demo video (silent, <=3 min) with Playwright.
All pages are local files — the VM's egress proxy blocks external pages
in headless Chromium, so the demo + proof are shown from local copies.
The live demo is at https://naplex666.github.io/tapelock/app/ (same files).
"""
import time
from playwright.sync_api import sync_playwright

BASE = "/home/hatch/workspace/xlayer-tapelock/video"
APP = "/home/hatch/workspace/xlayer-tapelock/app/index.html"


def show(page, url, seconds, actions=None):
    try:
        page.goto(url, wait_until="load", timeout=30000)
    except Exception as e:
        print("goto failed:", url, e)
        return
    time.sleep(2)
    if actions:
        try:
            actions(page)
        except Exception as e:
            print("actions failed:", e)
    time.sleep(max(0, seconds - 2))


def demo_actions(page):
    page.evaluate("window.scrollTo(0, 500)")
    time.sleep(1.5)
    try:
        page.fill("#seller", "0x7479B51bA685eF17B3F578a5720337A98e53e3cb")
        page.fill("#arbiter", "0x3Fe20F12c3fc578D662d95F3e000426848e40274")
        page.fill("#escrowId", "0")
    except Exception as e:
        print("fill failed:", e)
    page.evaluate("window.scrollTo(0, 1000)")
    time.sleep(1.5)
    page.evaluate("window.scrollTo(0, 1500)")
    time.sleep(1.5)
    page.evaluate("window.scrollTo(0, 0)")


with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    ctx = browser.new_context(
        viewport={"width": 1280, "height": 720},
        record_video_dir=f"{BASE}/raw",
        record_video_size={"width": 1280, "height": 720},
    )
    page = ctx.new_page()
    show(page, f"file://{BASE}/cards/card1.html", 9)
    show(page, f"file://{APP}", 30, demo_actions)
    show(page, f"file://{BASE}/cards/proof.html", 14)
    show(page, f"file://{BASE}/cards/card2.html", 10)
    show(page, f"file://{BASE}/cards/card3.html", 10)
    ctx.close()
    browser.close()
print("recording done")
