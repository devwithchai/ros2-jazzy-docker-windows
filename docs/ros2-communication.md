# ROS 2 Communication: Topics, Services and Actions

This guide demonstrates the three core ROS 2 communication patterns using a small custom example from the Packt *Mastering ROS 2 for Robotics Programming* repository.

The examples were validated in this project's ROS 2 Jazzy Docker environment on Windows + WSL 2 + WSLg.

> [Screenshot placeholder: Running ROS 2 communication demo overview]
>
> `<!-- Add screenshot here -->`

---

## Overview

ROS 2 provides three major communication patterns for application-level nodes:

```text
Topic
Publisher ───────────────► Subscriber

Service
Client ───── Request ─────► Server
Client ◄──── Response ◄──── Server

Action
Client ───── Goal ────────► Server
Client ◄──── Feedback ◄──── Server
Client ◄──── Result ◄────── Server
```

A practical rule of thumb:

| Mechanism | Best suited for |
|---|---|
| **Topic** | Continuous/asynchronous data streams |
| **Service** | Short request → response interactions |
| **Action** | Long-running operations with feedback and a final result |

Examples in robotics include sensor data and velocity commands for topics, configuration/query operations for services, and navigation/manipulation tasks for actions.

---

# 1. Prerequisites

Start the project's container:

```bash
cd ~/ros2_jazzy_dev
docker compose up -d
```

Enter it:

```bash
docker compose exec ros2 bash
```

Or from another PowerShell/WSL terminal:

```powershell
docker exec -it mastering_ros2_jazzy bash
```

Source the ROS 2 workspace:

```bash
source /ros2_ws/install/setup.bash
```

Confirm:

```bash
echo $ROS_DISTRO
```

Expected:

```text
jazzy
```

The examples below use the Packt Chapter 3 packages:

```text
master_ros2_interface
master_ros2_pkg
```

---

# 2. Custom interfaces used by the examples

The example package defines three custom interface types.

### Message

```text
master_ros2_interface/msg/CustomMsg
```

```text
string data
int32 number
```

### Service

```text
master_ros2_interface/srv/ConcatStrings
```

```text
string str1
string str2
---
string concatenated_str
```

### Action

```text
master_ros2_interface/action/MyCustomAction
```

```text
# Goal
int32 goal_value
---
# Result
int32 result_value
---
# Feedback
float32 progress
```

Inspect them yourself:

```bash
ros2 interface show master_ros2_interface/msg/CustomMsg
ros2 interface show master_ros2_interface/srv/ConcatStrings
ros2 interface show master_ros2_interface/action/MyCustomAction
```

> [Screenshot placeholder: `ros2 interface show` output]
>
> `<!-- Add screenshot here -->`

---

# 3. Topics

## What is a topic?

A topic is a named communication channel for asynchronous data.

A publisher writes messages to the topic; subscribers receive messages from it.

The publisher and subscriber do not directly call each other's C++ functions.

```text
Publisher Node
      |
      | CustomMsg
      v
 /custom_topic
      |
      | CustomMsg
      v
Subscriber Node
```

---

## Start the publisher

Terminal 1:

```bash
ros2 run master_ros2_pkg publisher_node
```

Open Terminal 2 and enter the same running container:

```bash
docker exec -it mastering_ros2_jazzy bash
source /ros2_ws/install/setup.bash
```

Start the subscriber if it is not already running:

```bash
ros2 run master_ros2_pkg subscriber_node
```

> [Screenshot placeholder: publisher and subscriber running]
>
> `<!-- Add screenshot here -->`

---

## Inspect the graph

```bash
ros2 node list
```

Example:

```text
/publisher_node
/subscriber_node
```

List topics:

```bash
ros2 topic list
```

The custom topic used by the example is:

```text
/custom_topic
```

Inspect it:

```bash
ros2 topic info /custom_topic
```

Expected pattern:

```text
Type: master_ros2_interface/msg/CustomMsg
Publisher count: 1
Subscription count: 1
```

> [Screenshot placeholder: `ros2 topic info /custom_topic`]
>
> `<!-- Add screenshot here -->`

---

## See the actual messages

```bash
ros2 topic echo /custom_topic
```

Example output:

```text
data: Custom Hello
number: 42
---
data: Custom Hello
number: 42
---
```

> [Screenshot placeholder: `ros2 topic echo /custom_topic`]
>
> `<!-- Add screenshot here -->`

Measure the rate:

```bash
ros2 topic hz /custom_topic
```

The example publisher produces approximately:

```text
average rate: 1.000
```

Small variations around 1 Hz are normal.

---

## Inspect the publisher

```bash
ros2 node info /publisher_node
```

The example publishes:

```text
/custom_topic: master_ros2_interface/msg/CustomMsg
/std_string_topic: std_msgs/msg/String
```

It also exposes standard ROS 2 parameter services and a `/rosout` publisher.

This is a useful reminder that a node can expose several ROS interfaces at once.

> [Screenshot placeholder: `ros2 node info /publisher_node`]
>
> `<!-- Add screenshot here -->`

---

## Topic takeaway

Use a topic when you want data to flow continuously and independently of a direct request/response interaction.

Typical robotics examples:

```text
/cmd_vel
/scan
/odom
/joint_states
/camera/image_raw
```

---

# 4. Services

## What is a service?

A service is a request/response interaction.

```text
Client
  |
  | Request
  v
Server
  |
  | Response
  v
Client
```

It is generally a better fit for discrete operations than for continuous streams.

---

## Start the service server

Terminal 1:

```bash
ros2 run master_ros2_pkg simple_server
```

The executable is named `simple_server`, but the ROS node is named:

```text
/string_concat_service
```

The service itself is:

```text
/concat_strings
```

This illustrates an important ROS 2 detail:

```text
Executable name != ROS node name
```

Inspect:

```bash
ros2 node list
ros2 node info /string_concat_service
```

> [Screenshot placeholder: service server and node info]
>
> `<!-- Add screenshot here -->`

---

## Inspect the service interface

```bash
ros2 service list
```

Find:

```text
/concat_strings
```

Check its type:

```bash
ros2 service type /concat_strings
```

Expected:

```text
master_ros2_interface/srv/ConcatStrings
```

Inspect the definition:

```bash
ros2 interface show master_ros2_interface/srv/ConcatStrings
```

Expected:

```text
string str1
string str2
---
string concatenated_str
```

> [Screenshot placeholder: service interface definition]
>
> `<!-- Add screenshot here -->`

---

## Call the service from the CLI

```bash
ros2 service call /concat_strings \
  master_ros2_interface/srv/ConcatStrings \
  "{str1: 'Hello ', str2: 'ROS 2'}"
```

Expected response:

```text
response:
master_ros2_interface.srv.ConcatStrings_Response(concatenated_str='Hello ROS 2')
```

Try another request:

```bash
ros2 service call /concat_strings \
  master_ros2_interface/srv/ConcatStrings \
  "{str1: 'Mastering ', str2: 'ROS 2'}"
```

Expected:

```text
concatenated_str='Mastering ROS 2'
```

> [Screenshot placeholder: successful CLI service call]
>
> `<!-- Add screenshot here -->`

If the CLI briefly says:

```text
waiting for service to become available...
```

it is waiting for service discovery. Once the server is discovered, the request can proceed.

---

## Run the Packt C++ client

Keep `simple_server` running.

In another terminal:

```bash
docker exec -it mastering_ros2_jazzy bash
source /ros2_ws/install/setup.bash
ros2 run master_ros2_pkg simple_client
```

Example:

```text
[string_concat_client]: Started ROS 2 Service Client
[string_concat_client]: Result: concatenated_str='Hello, World!'
```

This demonstrates that the same service can be used through:

```text
ROS 2 CLI client
        |
        +----> /concat_strings
        |
C++ client
```

> [Screenshot placeholder: Packt `simple_client` result]
>
> `<!-- Add screenshot here -->`

---

## Service takeaway

A service is appropriate when the interaction is naturally:

```text
"Do this / tell me this"
            |
            v
        response
```

Examples include resetting a subsystem, changing a configuration value, or requesting a discrete operation.

---

# 5. Actions

## What is an action?

An action is designed for a longer-running operation where a client may need:

- a goal
- progress feedback
- a final result
- cancellation support

Conceptually:

```text
Client
  |
  | Goal
  v
Action Server
  |
  +---- Feedback ---->
  |
  +---- Feedback ---->
  |
  +---- Feedback ---->
  |
  +---- Result ------>
```

This model is especially useful in robotics because operations such as navigation or robot-arm motion can take seconds or minutes.

---

## Inspect the custom action

```bash
ros2 interface show master_ros2_interface/action/MyCustomAction
```

Expected:

```text
# Goal
int32 goal_value
---
# Result
int32 result_value
---
# Feedback
float32 progress
```

> [Screenshot placeholder: action interface definition]
>
> `<!-- Add screenshot here -->`

---

## Start the action server

Terminal 1:

```bash
ros2 run master_ros2_pkg action_server
```

The ROS node is:

```text
/action_server
```

The action name is:

```text
/my_custom_action
```

---

## Inspect the action

```bash
ros2 action list
```

Expected:

```text
/my_custom_action
```

Then:

```bash
ros2 action info /my_custom_action
```

> [Screenshot placeholder: `ros2 action info /my_custom_action`]
>
> `<!-- Add screenshot here -->`

---

## Send a goal manually

```bash
ros2 action send_goal /my_custom_action \
  master_ros2_interface/action/MyCustomAction \
  "{goal_value: 5}" \
  --feedback
```

The example server loops from 1 through the goal value and publishes feedback every 0.5 seconds.

Expected pattern:

```text
Goal accepted

Feedback:
    progress: 1.0
Feedback:
    progress: 2.0
Feedback:
    progress: 3.0
Feedback:
    progress: 4.0
Feedback:
    progress: 5.0

Result:
    result_value: 5
```

The exact CLI formatting can differ slightly between ROS 2 releases.

> [Screenshot placeholder: action goal with live feedback and result]
>
> `<!-- Add screenshot here -->`

---

## Run the Packt C++ action client

Keep the action server running.

In another terminal:

```bash
docker exec -it mastering_ros2_jazzy bash
source /ros2_ws/install/setup.bash
ros2 run master_ros2_pkg action_client
```

The provided client sends:

```text
goal_value = 10
```

and prints feedback approximately like:


```text
Feedback: 1.00
Feedback: 2.00
...
Feedback: 10.00
Result: 10
```

> [Screenshot placeholder: Packt action client and server output]
>
> `<!-- Add screenshot here -->`

---

# 6. Compare the three mechanisms

```text
TOPIC

Publisher ───────────► /topic ───────────► Subscriber

Continuous/asynchronous data
```

```text
SERVICE

Client ───── request ─────► Server
Client ◄──── response ◄──── Server

Discrete request/response
```

```text
ACTION

Client ───── goal ────────► Server
Client ◄──── feedback ◄──── Server
Client ◄──── result ◄────── Server

Long-running operation
```

### Practical selection guide

Ask what your robot needs to communicate:

```text
Is it a stream of data?
        |
       Yes → Topic

Is it a short request with one response?
        |
       Yes → Service

Is it a long-running task where progress/result matter?
        |
       Yes → Action
```

---

# 7. Useful CLI commands

## Nodes

```bash
ros2 node list
ros2 node info <node_name>
```

## Topics

```bash
ros2 topic list
ros2 topic info <topic>
ros2 topic echo <topic>
ros2 topic hz <topic>
```

## Services

```bash
ros2 service list
ros2 service type <service>
ros2 service call <service> <type> <request>
```

## Actions

```bash
ros2 action list
ros2 action info <action>
ros2 action send_goal <action> <type> <goal> --feedback
```

## Interfaces

```bash
ros2 interface list
ros2 interface show <package>/<msg|srv|action>/<name>
```

---

# 8. Troubleshooting

### No nodes appear

Make sure the node process is actually running and that all terminals use the same ROS 2 environment:

```bash
echo $ROS_DISTRO
```

Expected:

```text
jazzy
```

### Package cannot be found

Source the workspace:

```bash
source /ros2_ws/install/setup.bash
```

Then:

```bash
ros2 pkg prefix master_ros2_pkg
```

### Topic has zero publishers/subscribers

Check the graph:

```bash
ros2 node list
ros2 topic info /custom_topic
```

The publishing/subscribing processes must be running.

### Service is unavailable

Make sure the server is running:

```bash
ros2 node list
ros2 service list
```

The service may take a short moment to become visible because of discovery.

### Action server is unavailable

Check:

```bash
ros2 action list
ros2 action info /my_custom_action
```

Start the `action_server` if necessary.

### Multiple chapter packages have the same name

Do not build the entire Packt repository indiscriminately. Build only the packages required by the current chapter.

Example:

```bash
colcon build \
  --symlink-install \
  --packages-up-to master_ros2_pkg
```

---

# 9. What these examples teach

The examples are intentionally small, but the communication patterns scale directly into larger robotic systems.

```text
Simple Chapter 3 example
          |
          v
Real robot system
```

The same concepts appear in larger systems:

```text
Sensors       → Topics
Commands      → Topics
Queries       → Services
Navigation    → Actions
Manipulation  → Actions
Configuration → Services
```

Later in a ROS 2 course, it becomes useful to stop thinking of a robot as one program and instead think of it as a **distributed graph of nodes communicating through typed interfaces**.

That is the core idea demonstrated by these three exercises.

---

## Verified in this project

The following flow was successfully tested in the Windows + Docker + WSL 2 ROS 2 Jazzy environment:

```text
Custom message generation       ✓
Topic publisher/subscriber       ✓
Custom topic inspection          ✓
Topic echo                       ✓
Topic rate measurement           ✓
Custom service generation        ✓
CLI service request/response     ✓
Packt C++ service client         ✓
Custom action generation         ✓
CLI action goal/feedback/result  ✓
Packt C++ action client          ✓
```

> [Screenshot placeholder: final ROS 2 communication validation montage]
>
> `<!-- Add screenshot here -->`

## Related

- Main project README: `../README.md`
- Windows + WSL 2 setup: `windows-wsl2.md`
- Troubleshooting: `troubleshooting.md`
