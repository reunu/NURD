import redis
import json
import time
import re

def replay_redis_commands(host='localhost', port=6379, input_file='redis_monitor_data.json'):
    regular_client = redis.Redis(host=host, port=port)  # Regular operations
    pubsub_client = redis.Redis(host=host, port=port)  # Dedicated for Pub/Sub if needed

    with open(input_file, 'r') as file:
        commands = json.load(file)

    start_time = time.time()
    pipeline = None

    for command in commands:
        current_time = time.time()
        elapsed_time = current_time - start_time
        sleep_time = command['elapsed_time'] - elapsed_time

        if sleep_time > 0:
            time.sleep(sleep_time)

        response = command['response']
        try:
            parts = re.findall(r'"(.*?)(?<!\\)"', response)
            if not parts:
                continue  # Skip non-command responses

            cmd = parts[0].upper()
            args = parts[1:]

            if cmd in ['SUBSCRIBE', 'PSUBSCRIBE', 'UNSUBSCRIBE', 'PUNSUBSCRIBE']:
                # Handle all Pub/Sub commands with a dedicated client
                pubsub_client.execute_command(cmd, *args)
            else:
                # Handle all other commands with the regular client
                if cmd == 'MULTI':
                    pipeline = regular_client.pipeline(transaction=True)
                elif cmd == 'EXEC':
                    if pipeline is not None:
                        pipeline.execute()
                        pipeline = None
                elif cmd == 'BRPOP' or cmd == 'BLPOP':
                    args.append(1)  # Append timeout of 1 second
                    regular_client.execute_command(cmd, *args)
                elif pipeline:
                    pipeline.execute_command(cmd, *args)
                else:
                    regular_client.execute_command(cmd, *args)
        except Exception as e:
            print(f"Error executing command {cmd} with args {args}: {str(e)}")
            if pipeline:
                pipeline.reset()

if __name__ == "__main__":
    replay_redis_commands()

