import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

// Define a TypeScript type for better safety
type TrashDetection = {
  location: {
    lat: number;
    lng: number;
  };
  trashType: string;
};

export const enrichDetectionWithArea = functions.firestore
  .document("detections/{docId}")
  .onCreate(async (snap: functions.firestore.DocumentSnapshot) => {
    const data = snap.data() as TrashDetection;
    const {lat, lng} = data.location;

    const nominatimUrl =
      "https://nominatim.openstreetmap.org/reverse?format=json" +
      `&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`;

    try {
      const res = await axios.get(nominatimUrl, {
        headers: {
          "User-Agent": "AGOS-Bot/1.0 (your_email@example.com)",
        },
      });

      const address = res.data.address || {};

      const area = {
        country: address.country || null,
        region: address.state || null,
        province: address.county || null,
        city: address.city || address.town || address.village || null,
        barangay:
          address.suburb ||
          address.neighbourhood ||
          address.quarter ||
          null,
      };

      await snap.ref.update({area});
    } catch (err: unknown) {
      if (err instanceof Error) {
        console.error("Reverse geocoding failed:", err.message);
      } else {
        console.error("Reverse geocoding failed:", err);
      }
    }
  });
