// Route de santé utilisée par la CI et par le déploiement
export function GET() {
  return Response.json({ status: "OK" });
}
