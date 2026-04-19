
# Game Design Document: *Event Horizon Drifter* (Working Title)

## 1. Narrative Premise and Arrival Context

The protagonist, designated **Operator-7**, conducted a deep-space exploration mission utilizing a vessel equipped with an **Antimatter Beamed-Core Propulsion System**. The mission profile was limited to a local cluster survey of three stellar systems. During the initial acceleration phase, a **cascade failure in the reaction control firmware** resulted in an uncontrolled lock of the antimatter injection valve. The vessel sustained a constant acceleration of 6g for a period of six months, achieving significant relativistic velocity before manual intervention regained control over the faulty system, enabling the executed of a deceleration burn.

Upon achieving relative rest in the vicinity of a gas giant within the circumstellar habitable zone, the vessel's **Penning Trap reserves are at 2.3 percent**. The onboard fusion reactor maintains life support and auxiliary power. The vessel is stranded approximately 1,000 light-years from the nearest human outpost.

The immediate environment includes **Thalassa-1b**, a tidally heated ocean moon classified as a water world with a single emergent volcanic landmass. Initial orbital spectrometry indicates the presence of anomalous heavy-element signatures at extreme depth, specifically the stabilized nuclear isomer **Thorium-229m**. Physics models suggest this material, when exposed to ultraviolet laser stimulation, undergoes induced gamma emission. The resulting photon cascade is sufficient to facilitate **pair production** for the synthesis of positrons and, consequently, antimatter fuel.

**Primary Objective:** Harvest sufficient Thorium-229m from the abyssal plain to manufacture new antimatter fuel pellets and execute a return trajectory.

---

## 2. Core Gameplay Loop

The primary interaction model is one of **Vertical Resource Progression**. The environment is hostile and inaccessible without incremental technological or biological adaptation. The gameplay loop is defined by a cyclical descent and retrieval pattern.

1.  **Orbital Scan & Anomaly Detection:** The vessel's limited sensor suite detects thermal, chemical, or electromagnetic anomalies at specific depth thresholds. These anomalies correspond to the presence of **Catalyst Materials** required for the Thorium-229m extraction process.
2.  **Depth-Specific Resource Acquisition:** The player descends to the identified biome layer. The objective is not immediate access to the seafloor but the acquisition of specific **Intermediary Components**:
    - Geothermal power taps.
    - High-pressure alloy feedstocks.
    - Rare-earth dopants for laser optics.
3.  **Base Expansion & Refinement:** Retrieved materials are processed in the **Refinery Array** (a modular structure anchored to the volcanic summit). This allows for the construction of **Upgrade Modules**. These modules are applied to either the **Submersible Vehicle** (hardware path) or the **Operator's Physiology** (bio-modification path).
4.  **Depth Threshold Breach:** With new capabilities (e.g., increased crush depth, enhanced sensory perception, improved thermal resistance), the player accesses the next deeper layer, where a new class of anomaly and resource is located.
5.  **The Abyssal Harvest:** Upon reaching the 200+ km layer, the loop shifts from preparation to **Extraction Logistics**. The player must manage cargo weight, energy draw from the mining laser, and evasion of abyssal megafauna while extracting Thorium-229m crystals.
6.  **Fuel Synthesis & Return Window:** Once sufficient mass of Thorium-229m is secured, the player initiates the **Antimatter Brewing Sequence**—a timed, high-energy process that draws all base power and requires defense against fauna attracted to the gamma radiation signature.

---

## 3. Technological Framework and Progression Vectors

The design bifurcates the player's approach to pressure and environment into two distinct but thematically linked progression trees: **Submersible Engineering** and **Somatic Modification**.

**3.1. Antimatter Production Technology (The MacGuffin Engine)**

- **Principle:** Relies on the **Thorium-229m Nuclear Battery** concept. The isomer possesses an exceptionally low excitation energy (8.28 eV), theoretically triggerable via ultraviolet laser.
- **The Refinery Module:** Constructed on the surface island. It houses a **Free-Electron Laser Array** powered by geothermal taps. The laser beam is directed at Thorium-229m crystals suspended in a vacuum chamber.
- **Reaction Chain:**
    1. **Induced Gamma Emission:** Thorium-229m decays to ground state, releasing a cascade of coherent gamma rays.
    2. **Pair Production:** Gamma rays strike a tungsten target, converting high-energy photons into **Electron-Positron Pairs**.
    3. **Magnetic Separation:** A superconducting magnet diverts positrons into a storage Penning Trap.
    4. **Antihydrogen Synthesis:** Cooled positrons are combined with antiprotons (generated by a small secondary accelerator using the fusion reactor's output) to form solid antihydrogen ice.
- **Gameplay Integration:** The player does not build the antimatter engine itself—that is part of the ship's existing hardware. The player builds the **Fuel Feedstock Harvester** for it.

**3.2. Submersible Path: *Hardware Progression***

This path treats the player's body as a vulnerable, baseline human entity contained within a life-support capsule. Progression is external and mechanical.

- **Depth Rating:** Pressure hull integrity is measured in **Atmospheres Absolute (ATA)** . Starting hull is rated for 500 ATA (approx 12.5 km depth on Thalassa-1b).
- **Incremental Upgrades:**
    - **MK I Abyssal Plating:** Requires **Hydrothermal Alloys** from 50 km vents. Raises rating to 2,000 ATA.
    - **MK II Resonance Dampener:** Requires **Luminous Reef Chitin** from 40-80 km. Reduces sonar signature to avoid mid-water predators.
    - **MK III Hadal Hull:** Requires **Dysprosium Salts** from 120 km Jovian Window. Raises rating to 10,000 ATA (seafloor capable).
- **Interface:** The player controls the vessel from a first-person cockpit perspective. HUD displays hull stress as a critical variable. Failure to upgrade results in **Rapid Unscheduled Disassembly** (implosion).

**3.3. Bio-Modification Path: *Somatic Progression***

This path involves direct alteration of the Operator's genome via retroviral vectors harvested from native extremophile life.

- **Pressure Adaptation:** The player's body must produce **Piezolytes**—organic molecules that prevent protein denaturation under extreme hydrostatic pressure. These are derived from enzymes found in deep-sea vent microbes.
- **Incremental Mutations:**
    - **Piezolyte Synthesis I:** Harvest from **Vent Tubeworms** at 20 km. Allows free swimming to 50 km without skeletal collapse.
    - **Bioluminescent Vision:** Harvest from **Luminous Reef Fauna**. Allows navigation of the Jovian Window shadow zone without artificial light (which attracts predators).
    - **Osmotic Gill Membrane:** Harvest from **Abyssal Vent Shrimp** at 150 km. Eliminates need for heavy breathing gas tanks; oxygen extracted directly from water.
    - **Ferro-Magnetic Sensitivity:** Detects the unique electromagnetic signature of Thorium-229m deposits.
- **Gameplay Consequence:** The bio-mod path eliminates the need for a bulky submersible, offering greater agility and stealth. However, it introduces **Genomic Instability**. Excessive modification without rest or specific stabilizing agents results in **Adverse Mutations** (e.g., visual distortion, reduced movement speed, pressure narcosis).

---

## 4. Depth Stratification and Objective Mapping

The following table outlines the clinical correlation between depth, biome pressure, and the resource objective driving the player's descent.

| Depth Range (km) | Designation | Environmental Pressure (ATA) | Primary Objective | Extraction Challenge |
| :--- | :--- | :--- | :--- | :--- |
| **0 - 50** | **Volcanic Flank** | 1 - 2,000 | **Geothermal Tap Deployment** | Corrosive vent fluids; aggressive territorial crustaceans. |
| **50 - 120** | **Twilight Trench** | 2,000 - 4,800 | **Acquisition of Alloy Feedstock** | Bioluminescent predators using pressure wave hunting. |
| **120 - 200** | **The Jovian Window** | 4,800 - 8,000 | **Acquisition of Rare-Earth Catalysts** | Time-gated visibility (eclipse cycle); migratory leviathan class fauna. |
| **200 - 247** | **Ice-VI Frontier** | 8,000 - 9,870 | **Thorium-229m Crystal Extraction** | Extreme pressure viscosity slowing movement; **Frost Wraith** patrols (large predator sensitive to laser vibrations). |
| **247+** | **Inner Ocean Void** | >9,870 | **Anomalous Data Logs** | Transition through Ice-VI melt shaft; total darkness; unknown biological entities. |

---

## 5. Ludic Tension and Failure States

The gameplay tension is derived from three interacting variables independent of player path choice:

1.  **Eclipse Cycle Pressure:** The 4.3-hour total eclipse of the gas giant creates a window of absolute darkness. While this reduces visual predator range, it allows **Abyssal Migrations**—creatures that normally cannot tolerate any light rise to upper layers to feed. Descents scheduled during the eclipse window are significantly more dangerous.
2.  **Viral Contamination Sub-Plot:** Operator-7's medical logs indicate a dormant **Xenomorphic Prion** from a previous expedition. This prion becomes active under high-pressure neurological stress. At depths below 150 km, the player (regardless of sub or bio-mod) experiences **Sensorium Distortion**—visual/auditory hallucinations. These hallucinations can mask real environmental threats (e.g., a leviathan's sonar ping sounds like a friendly beacon).
3.  **Energy Economy:** The ship's fusion reactor is finite. Every use of the mining laser, the refinery, or the submersible's active sonar consumes **Deuterium Reserves**. The player must find natural **Hydrothermal Power Taps** to recharge equipment, effectively tethering them to specific locations on the map.
