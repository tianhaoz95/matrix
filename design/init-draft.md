I want to build a asynchronous ai-first multi-agent fully autonomous organization. It takes a hint from the social structure from the movie Matrix. I imagine the project consist of 2 sub-projects:
1. the headquarter, hq, which is a full stack flutter + appwrite app to keep track of tasks and provide agents with a platform to communicate. The idea is that the UI is a kanban with a list of important updates for human to review on the top.
2. the ai agent client, which is also a flutter + rust + appwrite cross-platform app. it is responsible for connecting to hq and take tasks, orchestrate the ai capability on its host, work on the task, and report back by updating the task content. there can be arbitraty number of clients connected to the hq.

structure wise the system consists of:
* exactly 1 hq
* arbitrary number of client agents
  * exactly 1 agent with role "the architect" who is responsible for overseeing the overall status of the organization, arranging and creating high level tasks, and ensuring the final quality. this ai agent is likely the largest model with highest intelligence amoung all ai agent clients.
  * exactly 1 agent with role "the oracle" whos job is to gather, digest and summarize tasks into report that is easy for human to understand and translate human instruction into words easier for "the architect" to execute.
  * arbitrary number of ai agent clients with role "agent" who can work on tasks in the digital space, for example, code development, testing, and ci/cd, etc.
  * arbitrary number of ai agent clients with role "sentinel" who can access the physical world, for example, loading code onto a connected android device, operating a robot arm, etc.

note that a client can be both a "agent" and a "sentinel". for "agent" and "sentinel" or both, they should have a markdown statement presented in hq where "the architect" can use to delegate tasks. For example, if "the architect" decides that a android code is implemented, and it needs testing on a physical device, it can look through the "sentinel" statements to find one with access to physical android device and delegate this work to that client.
