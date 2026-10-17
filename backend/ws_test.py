"""Quick WS test - connects as a user, sends a hello message to another user."""
import asyncio
import json
import sys

import websockets


async def main(token: str, to_user_id: str):
    url = f"ws://localhost:8001/api/v1/ws/signal?token={token}"
    async with websockets.connect(url) as ws:
        print("connected")

        async def reader():
            try:
                while True:
                    msg = await ws.recv()
                    print("received:", msg)
            except Exception as e:
                print("reader ended:", e)

        r = asyncio.create_task(reader())

        await ws.send(json.dumps({
            "type": "offer",
            "to": to_user_id,
            "sdp": "test-offer-from-client",
        }))
        print("sent test offer")

        await asyncio.sleep(8)
        r.cancel()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python ws_test.py <token> <to_user_id>")
        sys.exit(1)
    asyncio.run(main(sys.argv[1], sys.argv[2]))
