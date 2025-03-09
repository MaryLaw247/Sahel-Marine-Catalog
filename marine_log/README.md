# Sahel Marine Catalog

A comprehensive smart contract-based registry for marine organism biometric data management, enabling researchers to catalog, track, and share deep-sea specimen information with robust validation and access controls.

## 🌊 Overview

The Sahel Marine Catalog implements a decentralized registry for marine biologists and oceanographers to document their deep-sea discoveries. Built on blockchain technology using Clarity smart contracts, it provides a secure, transparent, and immutable record of marine specimen data.

## ✨ Features

- **Comprehensive Specimen Registration**: Document species, classification, biology type, habitat conditions, and genome sequences
- **Environmental Parameter Validation**: Ensures scientific accuracy with built-in validation for depth, temperature, and salinity
- **Researcher Attribution**: Maintains clear ownership and attribution of specimen discoveries
- **Specimen Sealing**: Ability to make specimen records immutable once research is complete
- **Specimen Transfer**: Transfer research rights to other researchers
- **Privacy Controls**: Configurable sharing settings for each specimen
- **Efficient Querying**: Retrieve specimens by ID or researcher

## 🔍 Technical Overview

The Sahel Marine Catalog is implemented as a Clarity smart contract with the following key components:

- **Data Structures**: Sophisticated mapping for specimens and researcher tracking
- **Validation Logic**: Comprehensive parameter validation for scientific accuracy
- **Access Controls**: Authorization checks to ensure only authorized researchers can modify their own records
- **Error Handling**: Detailed error codes for robust application integration

## 📋 Key Functions

### Public Functions

| Function | Description |
|----------|-------------|
| `register-specimen` | Registers a new marine specimen with comprehensive metadata |
| `update-specimen-details` | Updates the details of an existing specimen |
| `seal-specimen-data` | Makes a specimen record immutable |
| `transfer-specimen` | Transfers research rights to another researcher |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-specimen` | Retrieves detailed information about a specific specimen |
| `get-specimens-by-researcher` | Lists all specimens cataloged by a specific researcher |
| `get-specimen-count` | Returns the total number of registered specimens |
| `is-specimen-shareable` | Checks if a specimen's data is publicly shareable |

## 🚀 Usage Examples

### Registering a New Specimen

```clarity
(contract-call? .sahel-marine-catalog register-specimen 
    "Mariana hadalis"                                ;; species
    "Kingdom: Animalia, Phylum: Chordata..."         ;; classification
    "Vertebrate"                                     ;; biology-type
    u8500                                            ;; depth-min (in mm)
    u10200                                           ;; depth-max (in mm)
    -50                                              ;; temperature (in centikelvin)
    35000                                            ;; salinity
    "ATCGGCTTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCT"  ;; genome-sequence
    true)                                            ;; is-shareable