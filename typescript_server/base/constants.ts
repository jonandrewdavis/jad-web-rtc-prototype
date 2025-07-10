import { secretKey } from "../configuration.json";

export class Constants {
  public static SecretKey: String = process.env.USER_ID || secretKey;
}
