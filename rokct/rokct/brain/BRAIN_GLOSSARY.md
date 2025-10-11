# Brain Module Glossary

This document explains the purpose and naming conventions for the core components of the Brain module.

## Core DocTypes

### 1. Synaptic Event

*   **What it was:** `Event Log`
*   **What it is:** A temporary, raw log of a single, unprocessed event that has occurred in the system.
*   **Why this name:** In neuroscience, a **synapse** is the junction where a single, raw nerve impulse is passed from one neuron to another. It's a fleeting, unprocessed signal. This name was chosen to reflect the DocType's role as the "nervous system" of the application, capturing the raw signal that "something happened" before it is processed into a long-term memory.

### 2. Engram

*   **What it was:** `Memory` / `Document Timeline`
*   **What it is:** The permanent, compounded, human-readable story of a document's entire lifecycle.
*   **Why this name:** An **engram** is the scientific term for a physical memory trace stored in the brain. It is the result of the brain processing raw signals and consolidating them into a persistent, long-term memory. This name was chosen to reflect this DocType's function as the permanent "long-term memory" of the business brain, holding the intelligent, summarized story of a document's history.

---

## Potential Future DocTypes & Concepts

As we continue to develop the "Action" pillar of the Brain module, here are some potential names for future components to maintain the scientific theme:

*   **Neuron:** Could represent a single, reusable piece of logic or a small, automated task.
*   **Cognitive Pattern:** Could be used to define a specific sequence of `Synaptic Events` that the system should look for (e.g., "Invoice Updated 3 times but never sent").
*   **Reflex Arc:** Could represent a complete, automated workflow: a `Cognitive Pattern` (the trigger) that fires a `Neuron` (the action).
*   **Cerebrum:** Could be the name for a future dashboard or UI that visualizes the activity and insights from the `Engram` records.
*   **Axon:** Could represent a connection to an external system or API.